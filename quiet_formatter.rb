RSpec::Support.require_rspec_core "formatters/base_text_formatter"

module RSpec
  module Core
    module Formatters
      class QuietFormatter < BaseTextFormatter
        TIME_FILE = ENV.fetch 'TIME_FILE'

        Formatters.register self,
                            :example_group_started,
                            :example_passed

        def initialize(*)
          super
          @group_level = 0
        end

        def example_group_started(notification)
          @num_total ||= begin
            n=0
            ObjectSpace.each_object Class do |o|
              n += 1 if o.ancestors.include? notification.group
            end
            n
          end
        end

        def example_passed(passed)
          @num_passed ||= 0
          @num_passed += 1
          @num_passed % 100 == 0 || @num_passed == @num_total and
            output.print "\r#{100*@num_passed/@num_total}%"
        end

        def dump_summary(summary)
          super
          File.open TIME_FILE, 'a' do |file|
            file.puts summary.duration
          end
        end
      end
    end
  end
end
