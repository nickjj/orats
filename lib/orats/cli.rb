require 'thor'
require 'orats/commands/project/exec'
require 'orats/commands/inventory'
require 'orats/commands/playbook'
require 'orats/commands/nuke'
require 'orats/commands/diff/exec'

module Orats
  class CLI < Thor
    option :pg_location, default: 'localhost', aliases: '-l'
    option :pg_username, default: 'postgres', aliases: '-u'
    option :pg_password, required: true, aliases: '-p'
    option :redis_location, default: 'localhost', aliases: '-n'
    option :redis_password, default: '', aliases: '-d'
    option :auth, type: :boolean, default: false, aliases: '-a'
    option :custom, default: '', aliases: '-c'
    option :skip_ansible, type: :boolean, default: false, aliases: '-A'
    option :skip_server_start, type: :boolean, default: false, aliases: '-F'
    option :sudo_password, default: '', aliases: '-s'
    option :skip_galaxy, type: :boolean, default: false, aliases: '-G'
    desc 'new TARGET_PATH [options]', ''
    long_desc <<-D
      `orats project target_path --pg-password supersecret` will create a new rails project and it will also create an ansible inventory to go with it by default.

      You must supply at least this flag:

      `--pg-password` to supply your development postgres password so the rails application can run database migrations

      Configuration:

      `--pg-location` to supply a custom postgres location [localhost]

      `--pg-username` to supply a custom postgres username [postgres]

      `--redis-location` to supply a custom redis location [localhost]

      `--redis-password` to supply your development redis password []

      Template features:

      `--auth` will include authentication and authorization [false]

      `--custom` will let you supply a custom template, a url or file is ok but urls must start with http or https []

      Project features:

      `--skip-ansible` skip creating the ansible related directories [false]

      `--skip-server-start` skip automatically running puma and sidekiq [false]

      Ansible features:

      `--sudo-password` to install ansible roles from the galaxy to a path outside of your user privileges []

      `--skip-galaxy` skip automatically installing roles from the galaxy [false]
    D

    def project(target_path)
      Commands::Project::Exec.new(target_path, options).init
    end

    option :sudo_password, default: '', aliases: '-s'
    option :skip_galaxy, type: :boolean, default: false, aliases: '-G'
    desc 'inventory TARGET_PATH [options]', ''
    long_desc <<-D
      `orats inventory target_path` will create an ansible inventory.

      Configuration:

      `--sudo-password` to install ansible roles from the galaxy to a path outside of your user privileges []

      `--skip-galaxy` skip automatically installing roles from the galaxy [false]
    D

    def inventory(target_path)
      Commands::Inventory.new(target_path, options).init
    end

    option :custom, default: '', aliases: '-c'
    desc 'playbook TARGET_PATH [options]', ''
    long_desc <<-D
      `orats playbook target_path` will create an ansible playbook.

      Template features:

      `--custom` will let you supply a custom template, a url or file is ok but urls must start with http or https []
    D

    def playbook(target_path)
      Commands::Playbook.new(target_path, options).init
    end

    option :skip_data, type: :boolean, default: false, aliases: '-D'
    option :redis_password, default: '', aliases: '-d'
    desc 'nuke TARGET_PATH [options]', ''
    long_desc <<-D
      `orats nuke target_path` will delete the directory and optionally all data associated to it.

      Options:

      `--skip-data` will skip deleting app specific postgres databases and redis namespaces [false]

      `--redis-password` to supply your development redis password []
    D

    def nuke(target_path)
      Commands::Nuke.new(target_path, options).init
    end

    option :hosts, default: '', aliases: '-h'
    option :inventory, default: '', aliases: '-i'
    option :playbook, default: '', aliases: '-b'
    desc 'diff [options]', ''
    long_desc <<-D
      `orats diff` will run various comparisons on orats and your ansible files.

      Help:

      `The green/yellow labels` denote a remote check to compare the files contained in your version of orats to the latest files on github.

      `The blue/cyan labels` denote a local check between the files contained in your version of orats to the files you have generated such as your own playbook or inventories.

      Options:

      `--hosts` to supply a hosts file for comparison []

      `--inventory` to supply an inventory directory/file for comparison []

      `--playbook` to supply a playbook directory/file for comparison []

      Quality of life features:

      `--inventory` also accepts a path to your project's inventory folder,
if you kept the default file names it will automatically compare both your
hosts and group_vars/all.yml files.

      `--playbook` also accepts a path to a playbook folder, if you kept the playbook name as `site.yml` it will automatically choose it.
    D

    def diff
      Commands::Diff::Exec.new(nil, options).init
    end

    desc 'version', ''
    long_desc <<-D
      `orats version` will print the current version.
    D

    def version
      puts "Orats version #{VERSION}"
    end

    map %w(-v --version) => :version

    private

    def invoked?
      caller_locations(0).any? { |backtrace| backtrace.label == 'invoke' }
    end
  end
end