require 'orats/commands/common'
require 'orats/commands/new/ansible'
require 'orats/commands/new/rails'
require 'orats/commands/new/server'

module Orats
  module Commands
    module New
      class Exec < Commands::Common
        include Ansible
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

            bundle_install
            bundle_binstubs
            spring_binstub

            create_and_migrate_database
            run_rake 'orats:favicons'
          end

          if @options[:auth]
            rails_template 'auth', '--skip ' do
              run_rake 'db:migrate db:seed'
            end
          end

          ansible_extras unless @options[:skip_extras]

          custom_rails_template unless @options[:template].empty?

          server_start unless @options[:skip_server_start]
        end

        private

        def services_path
          @options[:skip_extras] ?  @target_path : "#{@target_path}/services/#{File.basename @target_path}"
        end
      end
    end
  end
end