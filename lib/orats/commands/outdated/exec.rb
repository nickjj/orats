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

        def initialize(target_path = '', options = {})
          super

          @remote_galaxyfile = galaxyfile url_to_string(@remote_paths[:galaxyfile])
          @remote_inventory = inventory url_to_string(@remote_paths[:inventory])
          @remote_playbook = playbook url_to_string(@remote_paths[:playbook])

          @local_galaxyfile = galaxyfile file_to_string(@local_paths[:galaxyfile])
          @local_inventory = inventory file_to_string(@local_paths[:inventory])
          @local_playbook = playbook file_to_string(@local_paths[:playbook])
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
      end
    end
  end
end