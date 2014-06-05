require 'orats/version'
require 'orats/shell'
require 'orats/foreman'
require 'orats/ui'

module Orats
  class Execute
    include Thor::Base
    include Thor::Shell
    include Thor::Actions
    #source_root Dir.pwd

    include Shell
    include UI
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
        git_commit 'Change the postgres information'

        unless @options[:redis_password].empty?
          gsub_redis_info
          git_commit 'Add the redis password'
        end

        gsub_project_path
        git_commit 'Add the development project path'

        bundle_install
        git_commit 'Add gem lock file'

        bundle_binstubs
        git_commit 'Add binstubs for the important gems'

        spring_binstub
        git_commit 'Springify all of the bins'

        run_rake 'db:create:all db:migrate'
        git_commit 'Add the database schema file'
      end

      if @options[:auth]
        rails_template 'auth', '--skip ' do
          run_rake 'db:migrate db:seed'
        end
      end

      unless @options[:skip_extras]
        ansible_init @target_path
      end

      @active_path = services_path(@target_path)
      foreman_init
    end

    def play
      play_app @target_path
    end

    def nuke
      @active_path = @target_path

      nuke_warning

      nuke_data_details_warning unless @options[:skip_data]

      confirmed_to_delete = yes?('Are you sure? (y/N)', :cyan)

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
      def active_project
        File.basename @active_path
      end

      def services_path(target_path)
        @options[:skip_extras] ?  target_path : "#{target_path}/services/#{active_project}"
      end
  end
end