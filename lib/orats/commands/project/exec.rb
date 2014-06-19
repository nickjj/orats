require 'orats/commands/common'
require 'orats/commands/inventory'
require 'orats/commands/project/rails'
require 'orats/commands/project/server'

module Orats
  module Commands
    module Project
      class Exec < Commands::Common
        include Rails
        include Server

        def initialize(target_path = '', options = {})
          super

          @active_path = services_path
        end

        def init
          check_exit_conditions

          rails_template 'base' do
            gsub_postgres_info
            gsub_redis_info unless @options[:redis_password].empty?
            gsub_project_path
            gsub_readme

            bundle_install
            bundle_binstubs
            spring_binstub

            create_and_migrate_database
            generate_home_page
            generate_favicons
          end

          if @options[:auth]
            rails_template 'auth', '--skip ' do
              migrate_and_seed_database
            end
          end

          Commands::Inventory.new(@target_path,
                                  @options).init unless @options[:skip_ansible]

          custom_rails_template unless @options[:template].empty?

          server_start
        end

        private

        def services_path
          "#{@target_path}/services/#{File.basename @target_path}"
        end
      end
    end
  end
end