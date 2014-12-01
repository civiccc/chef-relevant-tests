require 'set'
require 'optparse'

module ChefRelevantTests
  class Cli
    class << self
      def parse_args!(argv)
        parser = OptionParser.new do |opts|
          opts.banner = <<-BANNER.strip
Usage: chef-relevant-tests [revision] [expander]
Available Expanders: #{EXPANDER_REGISTRY.keys.join ','}
BANNER
        end

        parser.parse!(argv)

        unless set_revision(ARGV.shift)
          puts "Error: Unknown revision.\n\n#{parser.help}"
          exit(1)
        end

        unless set_expander(ARGV.shift)
          puts "Error: Unknown expander.\n\n#{parser.help}"
          exit(1)
        end
      end

      def set_revision(rev)
        return unless system('git rev-parse #{rev} >/dev/null 2>&1')

        @@revision = rev
      end

      def set_expander(exp)
        return if !exp || exp.empty?

        @@expander = exp
      end

      def run
        changed_cookbooks = find_cookbook_diffs(@@revision)

        EXPANDER_REGISTRY[@@expander]
          .new(@@revision, changed_cookbooks)
          .expand
      end

      private

        CHANGE_DETECTOR_REGISTRY = [
          ChefRelevantTests::ChangeDetectors::Berkshelf,
        ].freeze

        EXPANDER_REGISTRY = {
          'test-kitchen' => ChefRelevantTests::Expanders::TestKitchen,
        }.freeze

        def find_cookbook_diffs(rev)
          enabled_change_detectors = CHANGE_DETECTOR_REGISTRY.map do |klass|
            detector = klass.new(rev)

            detector if detector.should_run?
          end.compact

          raise 'Unable to find changes - try `gem install berkshelf`.' if enabled_change_detectors.none?

          enabled_change_detectors.each_with_object(Set.new) do |detector, cookbooks|
            cookbooks.merge(detector.changed_cookbooks)
          end
        end
    end
  end
end
