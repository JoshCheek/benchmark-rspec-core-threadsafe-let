Dir.chdir File.dirname __FILE__

def title(title)
  puts "\n\e[35m== #{title} ==\e[39m"
end

def print_command(command)
  puts "\e[34m$ #{command.join ' '}\e[39m"
end

def run(*command)
  command = command.flatten
  print_command command
  system *command
  raise "Script failed!" unless $?.success?
end

def cd(dirname, &block)
  orig_dir = Dir.pwd
  print_command ['cd', dirname]
  Dir.chdir dirname, &block
  print_command ['cd', orig_dir]
end

def run_specs(specfile)
  run 'ruby', '-I', 'rspec-core/lib', 'rspec-core/exe/rspec',
              '-r', './quiet_formatter.rb',
              '-f', 'RSpec::Core::Formatters::QuietFormatter',
              specfile
end

n          = (ARGV.first || '7').to_i
specfile   = "#{n}_spec.rb"
time_file  = File.expand_path '../spec_times', __FILE__
master_sha = nil
thread_sha = nil
ENV['TIME_FILE'] = time_file


title 'Resetting environment'
run 'rm', '-rf', 'rspec',
                 'rspec-core',
                 'rspec-expectations',
                 'rspec-mocks',
                 'rspec-rails',
                 'rspec-support',
                 time_file



title "Cloning repos"
run 'git', 'clone', 'git@github.com:rspec/rspec-core.git'
cd 'rspec-core' do
  run 'git', 'remote', 'add', 'josh', 'https://github.com/JoshCheek/rspec-core.git'
  run 'git', 'remote', 'update'
  master_sha = %x[git merge-base master josh/threadsafe-let-block].strip
  thread_sha = %x[git log --pretty=format:"%H" -1 josh/threadsafe-let-block].strip
  run 'git', 'checkout', master_sha
  run 'sh', 'script/clone_all_rspec_repos'
end



title "Generating specs n=#{n} -- protip: Not worth going higher than 8"
run ["time", "ruby", "generate.rb", n.to_s, specfile]
run 'wc', '-l', specfile



title "Installing bundler against master (#{master_sha})"
run 'bundle', 'install'



title "Running specs against merge base"
run_specs specfile



title "Installing bundler against threadsafe-let-block (#{thread_sha})"
cd 'rspec-core' do
  run 'git', 'checkout', 'josh/threadsafe-let-block'
end
run 'bundle', 'install'



title "Running specs"
run_specs specfile


title 'Stats'
*old_results, normal, threadsafe = File.readlines(time_file).map(&:to_f)
puts "Depth:             \e[36m#{n}\e[39m"
puts "Normal:            \e[36m#{normal}\e[39m"
puts "Threadsafe:        \e[36m#{threadsafe}\e[39m"
puts "Difference:        \e[36m#{threadsafe - normal}\e[39m"

run 'du', '-h', specfile
run 'wc', '-l', specfile
run 'grep', '-c', 'example', specfile
run 'grep', '-c', 'let', specfile


title 'Running 9 more times (10 total)'
10.times do |i|
  puts "----- #{i} -----"

  %x[git -C rspec-core checkout #{master_sha}]
  run_specs specfile

  %x[git -C rspec-core checkout #{thread_sha}]
  run_specs specfile
end

master_times, threadsafe_times = File.readlines('spec_times').map(&:to_f).each_slice(2).to_a.transpose

mavg = master_times.inject(:+) / master_times.count
tavg = threadsafe_times.inject(:+) / threadsafe_times.count
tavg - mavg

puts "Average on master:     \e[36m#{mavg}\e[39m"
puts "Average on threadsafe: \e[36m#{tavg}\e[39m"
puts "Difference:            \e[36m#{tavg - mavg}\e[39m"
