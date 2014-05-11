require 'thor'
require 'orats/command'

module Orats
  class CLI < Thor
    option :pg_location, default: 'localhost'
    option :pg_username, default: 'postgres'
    option :pg_password, required: true
    option :redis_password, default: ''
    option :auth, type: :boolean, default: false, aliases: '-a'
    option :skip_cook, type: :boolean, default: false, aliases: '-C'
    option :skip_extras, type: :boolean, default: false, aliases: '-E'
    option :skip_foreman_start, type: :boolean, default: false, aliases: '-F'
    desc 'new APP_PATH [options]', ''
    long_desc <<-D
      `orats new myapp --pg-password supersecret` will create a new orats project and it will also create a chef cookbook to go with it by default.

      You must supply at least this flag:

      `--pg-password` to supply your development postgres password so the rails application can run database migrations

      Configuration:

      `--pg-location` to supply a custom postgres location [localhost]

      `--pg-username` to supply a custom postgres username [postgres]

      `--redis-password` to supply your development redis password [redis]

      Template features:

      `--auth` will include authentication and authorization [false]

      Project features:

      `--skip-cook` skip creating the cookbook [false]

      `--skip-extras` skip creating the services directory and cookbook [false]

      `--skip-foreman-start` skip automatically running puma and sidekiq [false]
    D
    def new(app_name)
      Command.new(app_name, options).new
    end

    desc 'cook APP_PATH', ''
    long_desc <<-D
      `orats cook myapp` will create a stand alone cookbook.
    D
    def cook(app_name)
      Command.new(app_name).cook
    end

    option :skip_data, type: :boolean, default: false, aliases: '-D'
    desc 'nuke APP_PATH [options]', ''
    long_desc <<-D
      `orats nuke myapp` will delete the directory and optionally all data associated to it.

      Options:

      `--skip-data` will skip deleting app specific postgres databases and redis namespaces [false]
    D
    def nuke(app_name)
      Command.new(app_name, options).nuke
    end

    desc 'version', ''
    long_desc <<-D
      `orats version` will print the current version.
    D
    def version
      Command.new.version
    end
    map %w(-v --version) => :version

    private
      def invoked?
        caller_locations(0).any? { |backtrace| backtrace.label == 'invoke' }
      end
  end
end