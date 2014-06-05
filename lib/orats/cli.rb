require 'thor'
require 'orats/command'

module Orats
  class CLI < Thor
    option :pg_location, default: 'localhost'
    option :pg_username, default: 'postgres'
    option :pg_password, required: true
    option :redis_location, default: 'localhost'
    option :redis_password, default: ''
    option :auth, type: :boolean, default: false, aliases: '-a'
    option :skip_extras, type: :boolean, default: false, aliases: '-E'
    option :skip_foreman_start, type: :boolean, default: false, aliases: '-F'
    option :sudo_password, default: ''
    option :skip_galaxy, type: :boolean, default: false, aliases: '-G'
    desc 'new APP_PATH [options]', ''
    long_desc <<-D
      `orats new myapp --pg-password supersecret` will create a new rails project and it will also create an ansible inventory to go with it by default.

      You must supply at least this flag:

      `--pg-password` to supply your development postgres password so the rails application can run database migrations

      Configuration:

      `--pg-location` to supply a custom postgres location [localhost]

      `--pg-username` to supply a custom postgres username [postgres]

      `--redis-location` to supply a custom redis location [localhost]

      `--redis-password` to supply your development redis password []

      Template features:

      `--auth` will include authentication and authorization [false]

      Project features:

      `--skip-extras` skip creating the services directory and ansible inventory/secrets [false]

      `--skip-foreman-start` skip automatically running puma and sidekiq [false]

      Ansible features:

      `--sudo-password` to install ansible roles from the galaxy to a path outside of your user privileges []

      `--skip-galaxy` skip automatically installing roles from the galaxy [false]
    D
    def new(app_name)
      Command.new(app_name, options).new
    end

    desc 'play PATH', ''
    long_desc <<-D
      `orats play path` will create an ansible playbook.
    D
    def play(app_name)
      Command.new(app_name).play
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

    option :playbook, default: ''
    option :inventory, default: ''
    desc 'outdated [options]', ''
    long_desc <<-D
      `orats outdated` will run various comparisons on your ansible files.

      Help:

      `The green/yellow labels` denote a remote check to compare the files contained in your version of orats to the latest files on github.

      `The blue/cyan labels` denote a local check between the files contained in your version of orats to the files you have generated such as your own playbook or inventories.

      Options:

      `--playbook` to supply a playbook file for comparison []

      `--inventory` to supply an inventory file for comparison []
    D
    def outdated
      Command.new(nil, options).outdated
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