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

n          = (ARGV.first || '7').to_i
filename   = "#{n}_spec.rb"
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
run ["time", "ruby", "generate.rb", n.to_s, filename]
run 'wc', '-l', filename



title "Installing bundler against master (#{master_sha})"
run 'bundle', 'install'



title "Running specs against merge base"
run 'ruby', '-I', 'rspec-core/lib', 'rspec-core/exe/rspec',
            '-r', './quiet_formatter.rb',
            '-f', 'RSpec::Core::Formatters::QuietFormatter',
            "#{n}_spec.rb"



title "Installing bundler against threadsafe-let-block (#{thread_sha})"
cd 'rspec-core' do
  run 'git', 'checkout', 'josh/threadsafe-let-block'
end
run 'bundle', 'install'



title "Running specs"
run 'ruby', '-I', 'rspec-core/lib', 'rspec-core/exe/rspec',
            '-r', './quiet_formatter.rb',
            '-f', 'RSpec::Core::Formatters::QuietFormatter',
            "#{n}_spec.rb"


title 'Stats'
lines = File.readlines(filename)
normal, threadsafe, *times = File.readlines(time_file).map(&:to_f)
raise unless times.empty?
puts "Depth:             \e[36m#{n}\e[39m"
puts "Normal:            \e[36m#{normal}\e[39m"
puts "Threadsafe:        \e[36m#{threadsafe}\e[39m"
puts "Difference:        \e[36m#{threadsafe - normal}\e[39m"
puts "Num lines in test: \e[36m#{lines.count}\e[39m"
puts "Num specs:         \e[36m#{lines.grep(/example/).count}\e[39m"
puts "Num let blocks:    \e[36m#{lines.grep(/let/).count}\e[39m"
