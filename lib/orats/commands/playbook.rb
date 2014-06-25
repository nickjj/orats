require 'orats/commands/common'
require 'orats/commands/project/rails'

module Orats
  module Commands
    class Playbook < Common
      include Project::Rails

      def initialize(target_path = '', options = {})
        super
      end

      def init
        exit_if_updating_playbook

        rails_template 'playbook'
        custom_rails_template unless @options[:custom].empty?

        galaxy_install
        log_success
      end

      private

      def exit_if_updating_playbook
        galaxyfile = File.join(@target_path, 'Galaxyfile')

        if File.exist?(galaxyfile)
          galaxy_install 'Update'
          exit 1
        end
      end

      def galaxy_install(git_commit_type='Add')
        log_task "#{git_commit_type} ansible roles from the galaxy"

        galaxy_install = "ansible-galaxy install -r #{@target_path}/Galaxyfile --roles-path #{@target_path}/roles --force"

        run galaxy_install

        git_commit "#{git_commit_type} galaxy installed roles"
      end

      def log_success
        log_status_top 'success', 'Everything has been setup successfully',
                       :cyan
        puts
        log_status_bottom 'question', 'Are most of your apps similar?', :yellow, true
        log_status_bottom 'answer', 'You only need to generate one playbook and you just did',
                          :white, true
        log_status_bottom 'answer', 'Use the inventory in each project to customize certain things', :white

        log_status_bottom 'question', 'Are you new to ansible?', :yellow, true
        log_status_bottom 'answer',
                          'http://docs.ansible.com/intro_getting_started.html',
                          :white
      end
    end
  end
end