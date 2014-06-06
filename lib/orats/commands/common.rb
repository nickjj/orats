require 'orats/commands/ui'

module Orats
  module Commands
    class Common
      include Thor::Base
      include Thor::Shell
      include Thor::Actions
      include UI

      RELATIVE_PATHS = {
          galaxyfile: 'templates/includes/Galaxyfile',
          inventory: 'templates/includes/inventory/group_vars/all.yml',
          playbook: 'templates/play.rb',
          version: 'version.rb'
      }

      REMOTE_FILE_PATHS = {} ; LOCAL_FILE_PATHS = {}

      def initialize(target_path = '', options = {})
        @target_path = target_path
        @options = options
        @active_path = @target_path

        self.destination_root = Dir.pwd
        @behavior = :invoke
      end

      private

      def base_path
        File.join(File.expand_path(File.dirname(__FILE__)), '..')
      end
    end
  end
end