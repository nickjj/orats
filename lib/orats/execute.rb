require 'orats/version'
require 'orats/shell'
require 'orats/foreman'
require 'orats/ui'
require 'orats/new/rails'
require 'orats/new/ansible'
require 'orats/nuke'
require 'orats/play'
require 'orats/outdated'

module Orats
  class Execute
    include Thor::Base
    include Thor::Shell
    include Thor::Actions
    #source_root Dir.pwd

    include Shell
    include UI
    include New::Rails
    include New::Ansible
    include Nuke
    include Play
    include Outdated
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

    def new
      @active_path = @target_path
      @active_path = services_path(@target_path)

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

      ansible_init(@target_path) unless @options[:skip_extras]

      foreman_init
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

    def outdated
      outdated_init
    end

    def version
      puts "Orats version #{VERSION}"
    end

    private

    def services_path(target_path)
      @options[:skip_extras] ?  target_path : "#{target_path}/services/#{File.basename @active_path}"
    end
  end
end