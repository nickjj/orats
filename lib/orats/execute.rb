require 'orats/version'
require 'orats/shell'
require 'orats/foreman'
require 'orats/cli/ui'
require 'orats/new/rails'
require 'orats/new/ansible'
#require 'orats/nuke'
#require 'orats/play'

module Orats
  class Execute
    include Thor::Base
    include Thor::Shell
    include Thor::Actions
    #source_root Dir.pwd

    include Shell
    include CLI::UI
    include New::Rails
    include New::Ansible
    include Nuke
    include Play
    include Foreman

    attr_accessor :active_path

    def initialize(target_path = '', options = {})
      @target_path = target_path
      @options = options

      # required to mix in thor actions without having a base thor class
      #@destination_stack = [self.class.source_root]
      self.destination_root = Dir.pwd
      @behavior = :invoke
    end

    def play
      play_init @target_path
    end

    def nuke
      @active_path = @target_path

      nuke_info
      nuke_details unless @options[:skip_data]

      confirmed_to_delete = yes?('Are you sure? (y/N)', :cyan); puts

      if confirmed_to_delete
        nuke_data unless @options[:skip_data]
        nuke_directory
      end
    end
  end
end