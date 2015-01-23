module ChefRelevantTests
  module Expanders
    class TestKitchen
      def initialize(rev, changed_cookbooks = [])
        @rev = rev
        @changed_cookbooks = changed_cookbooks
      end

      def expand
        require 'chef'
        require 'chef/knife'
        require 'kitchen'

        changed_kitchen_instances | kitchen_run_lists.map do |instance_name, run_list|
          instance_name if (@changed_cookbooks & expand_run_list(run_list)).any?
        end.compact
      end

      private

        # Separated for testability
        def get_kitchen_yml_to_compare
          old = nil
          new = nil

          Dir.mktmpdir do |dir|
            `git show #{@rev}:.kitchen.yml > #{dir}/.kitchen.yml`

            old = kitchen_config("#{dir}/.kitchen.yml")
            new = kitchen_config('.kitchen.yml')
          end

          [old, new]
        end

        def changed_kitchen_instances
          old, new = get_kitchen_yml_to_compare

          new.instances.keep_if do |instance|
            old_instance = old.instances.detect { |old| old.name == instance.name }

            !old_instance || instance.provisioner.config_keys.any? do |config_key|
              instance.provisioner[config_key] != old_instance.provisioner[config_key]
            end
          end.map(&:name)
        end

        # @return [Hash<String, Array>] Mapping of test-kitchen suite name to the run
        #   list specified in .kitchen.yml.
        def kitchen_run_lists
          c = kitchen_config('.kitchen.yml')

          Hash[c.instances.map { |i| [i.name, i.provisioner[:run_list]] }]
        end

        # Use Chef (and Knife configuration) to expand the run list in the .kitchen.yml
        # into a list of cookbooks.
        #
        # @return [Array] Cookbooks that have recipes that will be run
        def expand_run_list(run_list, environment = 'default')
          # Chef 11: Chef::Config.from_file(Chef::Knife.locate_config_file)
          Chef::Config.from_file(Chef::WorkstationConfigLoader.new(nil, Chef::Log).config_location)

          Chef::RunList.new(*run_list)
                       .expand(environment, 'disk')
                       .recipes
                       .map { |r| Chef::Recipe.parse_recipe_name(r) }
                       .map { |cookbook, _recipe| cookbook.to_s }
                       .uniq
        end

        def kitchen_config(kitchen_yml)
          Kitchen::Config.new(loader: Kitchen::Loader::YAML.new(:local_config => kitchen_yml))
        end
    end
  end
end
