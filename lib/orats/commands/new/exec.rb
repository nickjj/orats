require 'orats/common'
require 'orats/commands/new/rails'
require 'orats/commands/new/server'

module Orats
  module Commands
    module New
      # entry point to the new command
      class Exec < Common
        include Rails
        include Server

        AVAILABLE_TEMPLATES = {
          auth: 'add authentication and authorization'
        }

        def initialize(target_path = '', options = {})
          super
        end

        def init
          check_exit_conditions

          rails_template 'base' do
            rails_template_actions
          end

          orats_rails_template if template_exist?(@options[:template])
          custom_rails_template unless @options[:custom].empty?
          server_start
        end

        def available_templates
          puts
          log 'templates',
              'Add `-t TEMPLATE` to the new command to mixin a template',
              :magenta
          puts

          AVAILABLE_TEMPLATES.each_pair do |key, value|
            log key, value, :cyan
          end
        end

        private

        def orats_to_local(source, dest)
          includes_path = "#{base_path}/templates/includes"

          unless Dir.exist?(File.dirname(dest))
            system "mkdir -p #{File.dirname(dest)}"
          end

          system "cp #{includes_path}/#{source} #{dest}"
        end
      end
    end
  end
end
