require 'thor'
require 'orats/shell'
require 'orats/server'
require 'orats/version'

module Orats
  class CLI < Thor
    include Thor::Actions
    include Shell
    include Server

    attr_accessor :active_path, :active_project

    option :pg_location, default: 'localhost'
    option :pg_username, default: 'postgres'
    option :pg_password, required: true
    option :auth, type: :boolean, default: false, aliases: '-a'
    option :skip_cook, type: :boolean, default: false, aliases: '-C'
    option :skip_extras, type: :boolean, default: false, aliases: '-E'
    desc 'new APP_PATH [options]', ''
    long_desc <<-LONGDESC
      `orats new myapp --pg-password supersecret` will create a new orats project and it will also create a chef cookbook to go with it by default.

      You must supply at least this flag:

      `--pg-password` to supply your development postgres password so the rails application can run database migrations

      Configuration:

      `--pg-location` to supply a custom postgres location [localhost]

      `--pg-username` to supply a custom postgres username [postgres]

      Template features:

      `--auth` will include authentication and authorization [false]

      Project features:

      `--skip-cook` skip creating the cookbook [false]

      `--skip-extras` skip creating the services directory and cookbook [false]
  LONGDESC
    def new(app_name)
      @options = options
      @active_path = app_name

      @active_path = services_path(app_name)
      rails_template 'base' do
        gsub_postgres_info

        bundle_install
        git_commit 'Change the postgres information'
        git_commit 'Add gem lock file'

        run_rake 'db:create:all db:migrate db:test:prepare'
        git_commit 'Add the database schema file'
      end

      if options[:auth]
        rails_template 'auth', '--skip ' do
          run_rake 'db:migrate db:seed'
        end
      end

      unless options[:skip_cook] || options[:skip_extras]
        cook_app cookbooks_path(app_name)
      end

      @active_path = services_path(app_name)
      foreman_start unless invoked?
    end

    desc 'cook APP_PATH', ''
    long_desc <<-LONGDESC
      `orats cook myapp` will create a stand alone cookbook.
    LONGDESC
    def cook(app_name)
      @options = options
      @active_path = app_name

      cook_app app_name
    end

    option :skip_data, type: :boolean, default: false, aliases: '-S'
    desc 'nuke APP_PATH [options]', ''
    long_desc <<-LONGDESC
      `orats nuke myapp` will delete the directory and optionally all data associated to it.

      Options:

      `--skip-data` will skip deleting app specific postgres databases and redis namespaces [false]
    LONGDESC
    def nuke(app_name)
      @active_path = app_name

      puts
      say_status  'nuke', "\e[1mYou are about to permanently delete this directory:\e[0m", :red
      say_status  'path', "#{File.expand_path(@active_path)}", :yellow

      unless options[:skip_data]
        puts
        say_status  'nuke', "\e[1mYou are about to permanently delete these postgres databases:\e[0m", :red
        say_status  'databases', "#{active_project} and #{active_project}_test", :yellow
        puts
        say_status  'nuke', "\e[1mYou are about to permanently delete this redis namespace:\e[0m", :red
        say_status  'namespace', active_project, :yellow
      end
      puts

      confirmed_to_delete = yes?('Are you sure? (y/N)', :cyan)

      if confirmed_to_delete
        unless options[:skip_data]
          run_rake 'db:drop:all'
          nuke_redis
        end

        nuke_directory
      end
    end

    desc 'version', ''
    long_desc <<-LONGDESC
      `orats version` will print the current version.
    LONGDESC
    def version
      puts "Orats version #{VERSION}"
    end
    map %w(-v --version) => :version

    private

      def active_project
        @active_path.split('/').last
      end

      def services_path(app_name)
        options[:skip_extras] ?  app_name : "#{app_name}/services/#{active_project}"
      end

      def cookbooks_path(app_name)
        "#{app_name}/cookbooks/#{active_project}"
      end

      def invoked?
        caller_locations(0).any? { |backtrace| backtrace.label == 'invoke' }
      end
  end
end