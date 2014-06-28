require 'orats/commands/common'
require 'orats/commands/project/rails'

module Orats
  module Commands
    class Role < Common
      include Project::Rails

      def initialize(target_path = '', options = {})
        super
      end

      def init
        exit_if_invalid_role_name

        rails_template 'role'
        custom_rails_template unless @options[:custom].empty?

        repo_name = @options[:repo_name].empty? ? base_file_name :
            @options[:repo_name]

        log_task 'Update place holder repo name'
        gsub_file "#{@target_path}/README.md", 'repo_name',
                  repo_name
        gsub_file "#{@target_path}/tests/main.yml", 'repo_name',
                  repo_name
        git_commit 'Update place holder repo name'

        log_success
      end

      private

      def base_file_name
        File.basename(@target_path)
      end

      def exit_if_invalid_role_name
        log_task 'Check if role name is valid'

        unless base_file_name.count('.') == 1
          log_error 'error', 'Invalid role name', 'message',
                    "'#{base_file_name}' is invalid, it must contain 1 period",
                    true do
            log_status_bottom 'tip',
                              'Your role name should be github_user.role_name',
                              :white
          end

          exit 1
        end
      end

      def log_success
        log_status_top 'success', 'Everything has been setup successfully',
                       :cyan
        puts
        log_status_bottom 'question', 'What should you do next?', :yellow, true
        log_status_bottom 'answer', 'Check the readme in the role',
                          :white

        log_status_bottom 'question', 'Are you new to ansible?', :yellow, true
        log_status_bottom 'answer',
                          'http://docs.ansible.com/intro_getting_started.html',
                          :white
      end
    end
  end
end