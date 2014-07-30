require 'thor'
require 'orats/commands/new/exec'
require 'orats/commands/nuke'
require 'orats/version'

module Orats
  # the thor driven command line interface
  class CLI < Thor
    # if options are added through the .oratsrc file then we run the risk
    # of having options not set for the command it was ran for

    # for example the new command has a --template flag but the nuke command
    # does not. thor will throw an error if you have --template in the
    # .oratsrc config because it does not exist for the nuke command

    # the code below gets a list of options that came from the .oratsrc file
    # and compares them to the current options for the current command

    # this is good, but now we need a way to somehow add these options into
    # the command to fool thor into thinking they exist. we need to add
    # the option somehow, thoughts?

    # for now none of the code below is in action and the readme explicitly
    # says you can only store the postgres and redis credentials since
    # the args only get inserted into the new and nuke commands
    def initialize(args, local_options, config)
      super

      matched_options = []

      config[:current_command].options.each do |key|
        aliases = key[1].aliases
        option = key[0].to_s.gsub('_', '-')

        aliases.each do |item|
          matched_options << item if local_options.join.include?(item)
        end

        matched_options << option if local_options.include?("--#{option}")
      end
    end

    option :pg_location, default: 'localhost', aliases: '-l'
    option :pg_port, default: '5432', aliases: '-o'
    option :pg_username, default: 'postgres', aliases: '-u'
    option :pg_password, default: '', aliases: '-p'
    option :redis_location, default: 'localhost', aliases: '-n'
    option :redis_port, default: '6379', aliases: '-r'
    option :redis_password, default: '', aliases: '-d'
    option :template, default: '', aliases: '-t'
    option :custom, default: '', aliases: '-c'
    option :skip_server_start, type: :boolean, default: false, aliases: '-S'
    option :rc, default: ''
    desc 'new PATH [options]', 'Create a new orats application'
    long_desc File.read(File.join(File.dirname(__FILE__), 'cli_help/new'))
    def new(target_path)
      Commands::New::Exec.new(target_path, options).init
    end

    option :pg_location, default: 'localhost', aliases: '-l'
    option :pg_port, default: '5432', aliases: '-o'
    option :pg_username, default: 'postgres', aliases: '-u'
    option :pg_password, default: '', aliases: '-p'
    option :redis_location, default: 'localhost', aliases: '-n'
    option :redis_port, default: '6379', aliases: '-r'
    option :redis_password, default: '', aliases: '-d'
    option :skip_data, type: :boolean, default: false, aliases: '-D'
    option :rc, default: ''
    desc 'nuke PATH [options]', 'Delete a path and optionally its data'
    long_desc File.read(File.join(File.dirname(__FILE__), 'cli_help/nuke'))
    def nuke(target_path)
      Commands::Nuke.new(target_path, options).init
    end

    desc 'templates', 'Return a list of available templates'
    long_desc 'Return a list of available built in templates.'
    def templates
      Commands::New::Exec.new.available_templates
    end

    desc 'version', 'The current version of orats'
    long_desc 'Print the current version.'
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
