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
          @local_hosts      = hosts file_to_string(@local_paths[:hosts])
          @local_inventory  = inventory file_to_string(@local_paths[:inventory])
          @local_playbook   = playbook file_to_string(@local_paths[:playbook])
        end

        def init
          remote_to_local_gem_versions
          remote_to_local_galaxyfiles
          remote_to_local 'hosts', 'groups', @remote_hosts, @local_hosts
          remote_to_local 'inventory', 'variables', @remote_inventory, @local_inventory
          remote_to_local 'playbook', 'roles', @remote_playbook, @local_playbook

          local_to_user_hosts @options[:hosts] unless @options[:hosts].empty?

          unless @options[:inventory].empty?
            inventory_path = @options[:inventory]

            if File.directory?(inventory_path)
              hosts_path = File.join(inventory_path, 'hosts')

              inventory_path = File.join(inventory_path,
                                         'group_vars/all.yml')

              local_to_user_hosts hosts_path
            end

            local_to_user_inventory inventory_path
          end

          unless @options[:playbook].empty?
            playbook_path = @options[:playbook]

            if File.directory?(playbook_path)
              playbook_path = File.join(playbook_path, 'site.yml')

              local_to_user_playbook playbook_path
            end

            local_to_user_playbook playbook_path
          end
        end

        private

        def local_to_user_hosts(path)
          local_to_user('hosts', 'groups', path, @local_hosts) do
            hosts file_to_string(path)
          end
        end

        def local_to_user_inventory(path)
          local_to_user('inventory', 'variables', path, @local_inventory) do
            inventory file_to_string(path)
          end
        end

        def local_to_user_playbook(path)
          local_to_user('playbook', 'roles', path, @local_playbook) do
            playbook file_to_string(path)
          end
        end
      end
    end
  end
end