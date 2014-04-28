require 'orats/version'
require 'orats/shell'
require 'orats/foreman'

module Orats
  class Command
    include Thor::Base
    include Thor::Shell
    include Thor::Actions
    #source_root Dir.pwd

    include Shell
    include Foreman

    attr_accessor :active_path

    def initialize(app_name = '', options = {})
      @app_name = app_name
      @options = options

      # required to mix in thor actions without having a base thor class
      #@destination_stack = [self.class.source_root]
      self.destination_root = Dir.pwd
      @behavior = :invoke
    end

    def new
      @active_path = @app_name
      @active_path = services_path(@app_name)

      rails_template 'base' do
        gsub_postgres_info
        git_commit 'Change the postgres information'

        bundle_install
        git_commit 'Add gem lock file'

        spring_binstub

        run_rake 'db:create:all db:migrate'
        git_commit 'Add the database schema file'
      end

      if @options[:auth]
        rails_template 'auth', '--skip ' do
          run_rake 'db:migrate db:seed'
        end
      end

      unless @options[:skip_cook] || @options[:skip_extras]
        cook_app cookbooks_path(@app_name)
      end

      @active_path = services_path(@app_name)
      foreman_init
    end

    def cook
      cook_app @app_name
    end

    def nuke
      @active_path = @app_name

      nuke_warning

      nuke_data_details_warning unless @options[:skip_data]

      confirmed_to_delete = yes?('Are you sure? (y/N)', :cyan)

      if confirmed_to_delete
        nuke_data unless @options[:skip_data]

        nuke_directory
      end
    end

    def version
      puts "Orats version #{VERSION}"
    end

    private
      def active_project
        File.basename @active_path
      end

      def services_path(app_name)
        @options[:skip_extras] ?  app_name : "#{app_name}/services/#{active_project}"
      end

      def cookbooks_path(app_name)
        "#{app_name}/cookbooks/#{active_project}"
      end
  end
end