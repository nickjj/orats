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

        attr_accessor :diff_list

        def initialize(target_path = '', options = {})
          super

          @remote_galaxyfile = galaxyfile url_to_string(@remote_paths[:galaxyfile])
          @remote_playbook   = playbook url_to_string(@remote_paths[:playbook])
          @remote_hosts      = hosts url_to_string(@remote_paths[:hosts])
          @remote_inventory  = inventory url_to_string(@remote_paths[:inventory])

          galaxyfile_path = @options[:galaxyfile]
          playbook_path   = @options[:playbook]
          hosts_path      = @options[:hosts]
          inventory_path  = @options[:inventory]

          if !@options[:inventory].empty? && File.directory?(@options[:inventory])
            hosts_path     = File.join(inventory_path, 'hosts')
            inventory_path = File.join(inventory_path, 'group_vars/all.yml')
          end

          if !@options[:playbook].empty? && File.directory?(@options[:playbook])
            galaxyfile_path = File.join(playbook_path, 'Galaxyfile')
            playbook_path   = File.join(playbook_path, 'site.yml')
          end

          @your_galaxyfile = galaxyfile file_to_string (galaxyfile_path) unless galaxyfile_path.empty?
          @your_playbook   = playbook file_to_string(playbook_path) unless playbook_path.empty?
          @your_hosts      = hosts file_to_string(hosts_path) unless hosts_path.empty?
          @your_inventory  = inventory file_to_string(inventory_path) unless inventory_path.empty?

        end

        def init
          remote_gem_vs_yours

          remote_vs_yours('galaxyfile', @remote_galaxyfile,
                          @your_galaxyfile, false) unless @your_galaxyfile.nil?
          remote_vs_yours('playbook', @remote_playbook,
                          @your_playbook, true) unless @your_playbook.nil?
          remote_vs_yours('hosts', @remote_hosts,
                          @your_hosts, true) unless @your_hosts.nil?
          remote_vs_yours('inventory', @remote_inventory,
                          @your_inventory, true) unless @your_inventory.nil?
        end
      end
    end
  end
end