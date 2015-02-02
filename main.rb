Dir.chdir File.dirname __FILE__

def title(title)
  puts "\n\e[35m== #{title} ==\e[39m"
end

def run(*command)
  command = command.flatten
  puts "\e[34m$ #{command.join ' '}\e[39m"
  system *command
end

n = 6
filename = "#{n}_spec.rb"

title "Generating specs n=#{n} -- protip: Not worth going higher than 8"
run ["time", "ruby", "generate.rb", n.to_s, filename]
run 'wc', '-l', filename

title "Installing bundler with rspec-core on Rubygems"
run 'bundle', 'install'

title "Running specs"
run %W[bundle exec rspec
           -r ./quiet_formatter.rb
           -f RSpec::Core::Formatters::QuietFormatter
           #{n}_spec.rb
          ]

title "Installing bundler with rspec-core on branch threadsafe-let-block"
ENV['THREADSAFE_RSPEC'] = 't'
run 'bundle', 'install'

title "Running specs"
run %W[bundle exec rspec
           -r ./quiet_formatter.rb
           -f RSpec::Core::Formatters::QuietFormatter
           #{n}_spec.rb
          ]
