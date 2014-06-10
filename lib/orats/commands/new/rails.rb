module Orats
  module Commands
    module New
      module Rails
        def check_exit_conditions
          exit_if_cannot_access 'rails', 'You can install it by running `gem install rails`'
          exit_if_process_not_running 'postgres', 'redis'
          exit_if_path_exists
        end

        def rails_template(command, flags = '')
          orats_template = "--template #{base_path}/templates/#{command}.rb"

          run "rails new #{@active_path} #{flags} --skip-bundle #{orats_template unless command.empty?}"
          yield if block_given?
        end

        def custom_rails_template
          log_task 'Run custom rails template'

          @options[:template].include?('://') ? url_to_string(@options[:template])
                                               : file_to_string(@options[:template])

          rails_template '', "--skip --template #{@options[:template]}"
        end

        def gsub_postgres_info
          log_task 'Update the postgres connection details'
          gsub_file "#{@active_path}/.env", 'DATABASE_HOST: localhost', "DATABASE_HOST: #{@options[:pg_location]}"
          gsub_file "#{@active_path}/.env", ': postgres', ": #{@options[:pg_username]}"
          gsub_file "#{@active_path}/.env", ': supersecrets', ": #{@options[:pg_password]}"

          git_commit 'Update the postgres connection details'
        end

        def gsub_redis_info
          log_task 'Update the redis connection details'
          gsub_file "#{@active_path}/.env", 'HE_PASSWORD: ""', "HE_PASSWORD: #{@options[:redis_password]}"
          gsub_file "#{@active_path}/.env", 'CACHE_HOST: localhost', "CACHE_HOST: #{@options[:redis_location]}"

          git_commit 'Update the redis connection details'
        end

        def gsub_project_path
          log_task 'Update the project path'
          gsub_file "#{@active_path}/.env", ': /full/path/to/your/project', ": #{File.expand_path(@active_path)}"

          git_commit 'Update the project path'
        end

        def bundle_install
          log_task 'Run bundle install, this may take a while'
          run_from @active_path, 'bundle install'

          git_commit 'Add Gemfile.lock'
        end

        def bundle_binstubs
          log_task 'Run bundle binstubs for a few gems'
          run_from @active_path, 'bundle binstubs whenever puma sidekiq backup'

          git_commit 'Add binstubs for the important gems'
        end

        def spring_binstub
          log_task 'Run spring binstub'
          run_from @active_path, 'bundle exec spring binstub --all'

          git_commit 'Add spring binstubs for all of the bins'
        end

        def run_rake(command)
          log_task 'Run rake command'

          run_from @active_path, "bundle exec rake #{command}"
        end

        def create_and_migrate_database
          run_rake 'db:create:all db:migrate'
          git_commit 'Add the database schema file'
        end
      end
    end
  end
end