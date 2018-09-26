# frozen_string_literal: true

require 'thor'
require 'orats/commands/new'
require 'orats/version'

module Orats
  # thor driven command line interface
  class CLI < Thor
    option :template, default: 'base', aliases: '-t'
    desc 'new PATH [options]', 'Create a new orats application'
    long_desc File.read(File.join(File.dirname(__FILE__), 'cli_help/new'))
    def new(target_path)
      Commands::New.new(target_path, options).init
    end

    desc 'templates', 'Return a list of available templates'
    long_desc 'Return a list of available built in templates.'
    def templates
      Commands::New.new.available_templates
    end

    desc 'version', 'The current version of orats'
    long_desc 'Print the current version.'
    def version
      puts "orats version #{VERSION}"
    end

    map %w(-v --version) => :version

    private

    def invoked?
      caller_locations(0).any? { |backtrace| backtrace.label == 'invoke' }
    end
  end
end
