module ChefRelevantTests
  module ChangeDetectors
    class Berkshelf
      def initialize(ref)
        @ref = ref
      end

      def should_run?
        load_dependencies
        !!defined?(Berkshelf)
      end

      def changed_cookbooks
        load_dependencies

        changed_cookbooks = []
        dependent_cookbooks = []

        old, new = get_berksfiles_to_compare

        # `old` and `new` are both in the format
        # [["cookbook_name", "0.0.2"], ...]
        #
        # So, the changed cookbooks are the ones that appear in the new version but
        # not the old version. This should also filter any cookbooks which no longer
        # exist.
        diff = berksfile_locked_versions(new) - berksfile_locked_versions(old)

        changed_cookbooks = diff.map(&:first)

        dependent_cookbooks = changed_cookbooks.map { |name| berksfile_dependent_upon(new, name) }.flatten

        changed_cookbooks | dependent_cookbooks
      end

      private

        def load_dependencies
          begin
            require 'berkshelf'
          rescue LoadError
            return false
          end
        end

        # Separated for testability
        def get_berksfiles_to_compare
          Dir.mktmpdir do |dir|
            `git show #{@ref}:Berksfile.lock > #{dir}/Berksfile.lock`
            old = ::Berkshelf::Lockfile.from_file("#{dir}/Berksfile.lock")
            new = ::Berkshelf::Lockfile.from_file('Berksfile.lock')

            [old, new]
          end
        end

        # The vertices in the Berkshelf-produced graph are the version-locked
        # cookbooks (the part of the Berksfile.lock after "GRAPH")
        #
        # @param lockfile [Berkshelf::Lockfile] Lockfile to analyze
        # @return [Array<Array>] for each locked cookbook, an array with two elements:
        #   first, cookbook name
        #   second, cookbook version
        def berksfile_locked_versions(lockfile)
          lockfile.graph.map { |g| [g.name, g.version] }
        end

        # Traverse the Berkshelf dependency graph to find any other cookbooks that
        # include a dependency on the target cookbook.
        #
        # @param lockfile [Berkshelf::Lockfile]
        # @param cookbook [String]
        # @return [Array] Names of dependent cookbooks
        def berksfile_dependent_upon(lockfile, cookbook)
          lockfile.graph.select { |n| n.dependencies.include?(cookbook) }.map(&:name)
        end
    end
  end
end
