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

n         = 6
filename  = "#{n}_spec.rb"
time_file = File.expand_path '../spec_times', __FILE__
ENV['TIME_FILE'] = time_file

# Reset
title 'Resetting environment'
run 'rm', '-rf', 'rspec',
                 'rspec-core',
                 'rspec-expectations',
                 'rspec-mocks',
                 'rspec-rails',
                 'rspec-support',
                 time_file

# get code
title "Cloning repos"
run 'git', 'clone', 'git@github.com:rspec/rspec-core.git'
cd 'rspec-core' do
  run 'git', 'remote', 'add', 'josh', 'https://github.com/JoshCheek/rspec-core.git'
  run 'git', 'remote', 'update'
  merge_base = '655a52b03fd00c3d64554c4268e8da3ac0bd587c'
  run 'git', 'checkout', merge_base
  run 'sh', 'script/clone_all_rspec_repos'
end

# against master
title "Generating specs n=#{n} -- protip: Not worth going higher than 8"
run ["time", "ruby", "generate.rb", n.to_s, filename]
run 'wc', '-l', filename

title "Installing bundler with rspec-core on Rubygems"
run 'bundle', 'install'

title "Running specs against merge base"
run 'ruby', '-I', 'rspec-core/lib', 'rspec-core/exe/rspec',
            '-r', './quiet_formatter.rb',
            '-f', 'RSpec::Core::Formatters::QuietFormatter',
            "#{n}_spec.rb"

# against threadsafe branch
title "Running against threadsafe-let-block"
cd 'rspec-core' do
  run 'git', 'checkout', 'josh/threadsafe-let-block'
end
run 'bundle', 'install'

title "Running specs"
run 'ruby', '-I', 'rspec-core/lib', 'rspec-core/exe/rspec',
            '-r', './quiet_formatter.rb',
            '-f', 'RSpec::Core::Formatters::QuietFormatter',
            "#{n}_spec.rb"

# difference
title 'Difference'
normal, threadsafe, *times = File.readlines(time_file).map(&:to_f)
raise "wat?" unless times.empty?
puts "Normal:     \e[36m#{normal}\e[39m"
puts "Threadsafe: \e[36m#{threadsafe}\e[39m"
puts "Difference: \e[36m#{threadsafe - normal}\e[39m"

