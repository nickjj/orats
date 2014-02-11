require 'thor'
require 'orats/shell'
require 'orats/server'

module Orats
  class Orats < Thor
    include Thor::Actions
    include Shell
    include Server

    attr_accessor :app_name, :app_name_only

    class_option :postgres_location, default: 'localhost'
    class_option :postgres_username, default: 'postgres'

    option :postgres_password, required: true
    desc 'base APP_NAME', 'Create a new rails application using the base template.'
    def base(app_name)
      @app_name = app_name

      run "rails new #{@app_name} --skip-bundle --template #{File.expand_path File.dirname(__FILE__)}/templates/commands/base.rb"

      gsub_postgres_info options
      git_commit 'Change the postgres information'

      bundle_install
      git_commit 'Add gem lock file'

      run_rake 'db:create:all db:migrate db:test:prepare'
      git_commit 'Add the database schema file'

      foreman_start unless invoked?
    end

    option :postgres_password, required: true
    desc 'auth APP_NAME', 'Create a new rails application with authentication/authorization.'
    def auth(app_name)
      @app_name = app_name

      invoke :base

      run "rails new #{@app_name} --skip --skip-bundle --template #{File.expand_path File.dirname(__FILE__)}/templates/commands/auth.rb"

      run_rake 'db:migrate db:seed'

      foreman_start unless invoked?
    end

    desc 'nuke APP_NAME', 'Delete an application and optionally its postgres databases and redis namespace.'
    option :postgres_password, required: false
    option :delete_data, type: :boolean, default: true
    def nuke(app_name)
      @app_name = app_name

      puts
      say_status  'nuke', "\e[1mYou are about to permanently delete this directory:\e[0m", :red
      say_status  'path', "#{File.expand_path(@app_name)}", :yellow

      if options[:delete_data]
        puts
        say_status  'nuke', "\e[1mYou are about to permanently delete these postgres databases:\e[0m", :red
        say_status  'databases', "#{app_name_only} and #{app_name_only}_test", :yellow
        puts
        say_status  'nuke', "\e[1mYou are about to permanently delete this redis namespace:\e[0m", :red
        say_status  'namespace', app_name_only, :yellow
      end
      puts

      confirmed_to_delete = yes?('Are you sure? (y/N)', :cyan)

      if confirmed_to_delete
        if options[:delete_data]
          run_rake 'db:drop:all'
          nuke_redis
        end

        nuke_directory
      end
    end

    private
      def app_name_only
        @app_name.split('/').last
      end

      def invoked?
        caller_locations(0).any? { |backtrace| backtrace.label == 'invoke' }
      end
  end
end