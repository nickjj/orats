require 'orats/new/ansible'
require 'orats/new/rails'
require 'orats/new/foreman'

module Orats
  module New
    class Exec
      include Thor::Base
      include Thor::Shell
      include Thor::Actions
      include Orats::UI
      include Ansible
      include Rails
      include Foreman

      def initialize(target_path = '', options = {})
        @target_path = target_path
        @options = options
        @active_path = services_path(@target_path)

        self.destination_root = Dir.pwd
        @behavior = :invoke
      end

      def init
        rails_template 'base' do
          gsub_postgres_info
          gsub_redis_info unless @options[:redis_password].empty?
          gsub_project_path

          bundle_install
          bundle_binstubs
          spring_binstub

          create_and_migrate_database
        end

        if @options[:auth]
          rails_template 'auth', '--skip ' do
            run_rake 'db:migrate db:seed'
          end
        end

        ansible_extras unless @options[:skip_extras]
        foreman_start unless @options[:skip_foreman_start]
      end

      private

      def services_path(target_path)
        @options[:skip_extras] ?  target_path : "#{target_path}/services/#{File.basename target_path}"
      end
    end
  end
end