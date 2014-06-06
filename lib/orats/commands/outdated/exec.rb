require 'orats/commands/common'
require 'orats/version'
require 'orats/commands/outdated/parse'
require 'orats/commands/outdated/compare'

module Orats
  module Commands
    module Outdated
      class Exec < Commands::Common
        include Parse
        include Compare

        def initialize(options = {})
          @options = options

          @remote_gem_version = gem_version

          build_common_paths

          @remote_galaxyfile = galaxyfile url_to_string(REMOTE_FILE_PATHS[:galaxyfile])
          @remote_inventory = inventory url_to_string(REMOTE_FILE_PATHS[:inventory])
          @remote_playbook = playbook url_to_string(REMOTE_FILE_PATHS[:playbook])

          @local_galaxyfile = galaxyfile file_to_string(LOCAL_FILE_PATHS[:galaxyfile])
          @local_inventory = inventory file_to_string(LOCAL_FILE_PATHS[:inventory])
          @local_playbook = playbook file_to_string(LOCAL_FILE_PATHS[:playbook])
        end

        def init
          remote_to_local_gem_versions
          remote_to_local_galaxyfiles
          remote_to_local 'inventory', 'variables', @remote_inventory, @local_inventory
          remote_to_local 'playbook', 'roles', @remote_playbook, @local_playbook

          unless @options[:playbook].empty?
            local_to_user('playbook', 'roles', @options[:playbook], @local_playbook) do
              playbook file_to_string(@options[:playbook])
            end
          end

          unless @options[:inventory].empty?
            local_to_user('inventory', 'variables', @options[:inventory], @local_inventory) do
              inventory file_to_string(@options[:inventory])
            end
          end
        end

        private

        def repo_path
          %w(https://raw.githubusercontent.com/nickjj/orats lib/orats)
        end

        def build_common_paths
          files = [:galaxyfile, :inventory, :playbook]

          files.each do |file|
            LOCAL_FILE_PATHS[file] = "#{base_path}/#{RELATIVE_PATHS[file]}"
            REMOTE_FILE_PATHS[file] = "#{repo_path[0]}/#{@remote_gem_version}/#{repo_path[1]}/#{RELATIVE_PATHS[file]}"
          end
        end
      end
    end
  end
end