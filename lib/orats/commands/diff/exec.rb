require 'orats/commands/common'
require 'orats/commands/diff/parse'
require 'orats/commands/diff/compare'
require 'orats/version'

module Orats
  module Commands
    module Diff
      class Exec < Commands::Common
        include Parse
        include Compare

        def initialize(target_path = '', options = {})
          super

          @remote_galaxyfile = galaxyfile url_to_string(@remote_paths[:galaxyfile])
          @remote_hosts      = hosts url_to_string(@remote_paths[:hosts])
          @remote_inventory  = inventory url_to_string(@remote_paths[:inventory])
          @remote_playbook   = playbook url_to_string(@remote_paths[:playbook])

          @local_galaxyfile = galaxyfile file_to_string(@local_paths[:galaxyfile])
          @local_hosts      = hosts url_to_string(@local_paths[:hosts])
          @local_inventory  = inventory file_to_string(@local_paths[:inventory])
          @local_playbook   = playbook file_to_string(@local_paths[:playbook])
        end

        def init
          remote_to_local_gem_versions
          remote_to_local_galaxyfiles
          remote_to_local 'hosts', 'groups', @remote_hosts, @local_hosts
          remote_to_local 'inventory', 'variables', @remote_inventory, @local_inventory
          remote_to_local 'playbook', 'roles', @remote_playbook, @local_playbook

          unless @options[:hosts].empty?
            local_to_user('hosts', 'groups', @options[:hosts], @local_hosts) do
              hosts file_to_string(@options[:hosts])
            end
          end

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