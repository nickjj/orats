module Orats
  module Commands
    module New
      module Rails
        def rails_template(command, flags = '')
          exit_if_cannot_rails
          exit_if_exists unless flags.index(/--skip/)

          run "rails new #{@active_path} #{flags} --skip-bundle --template #{base_path}/templates/#{command}.rb"
          yield if block_given?
        end

        def gsub_postgres_info
          log_thor_task 'root', 'Changing the postgres information'
          gsub_file "#{@active_path}/.env", 'DATABASE_HOST: localhost', "DATABASE_HOST: #{@options[:pg_location]}"
          gsub_file "#{@active_path}/.env", ': postgres', ": #{@options[:pg_username]}"
          gsub_file "#{@active_path}/.env", ': supersecrets', ": #{@options[:pg_password]}"

          git_commit 'Change the postgres information'
        end

        def gsub_redis_info
          log_thor_task 'root', 'Adding the redis password'
          gsub_file "#{@active_path}/config/initializers/sidekiq.rb", '//', "//:#{ENV['CACHE_PASSWORD']}@"
          gsub_file "#{@active_path}/.env", 'HE_PASSWORD: ', "HE_PASSWORD: #{@options[:redis_password]}"
          gsub_file "#{@active_path}/.env", 'CACHE_HOST: localhost', "CACHE_HOST: #{@options[:redis_location]}"
          gsub_file "#{@active_path}/config/application.rb", '# pass', 'pass'

          git_commit 'Add the redis password'
        end

        def gsub_project_path
          log_thor_task 'root', 'Changing the project path'
          gsub_file "#{@active_path}/.env", ': /full/path/to/your/project', ": #{File.expand_path(@active_path)}"

          git_commit 'Add the development project path'
        end

        def bundle_install
          log_thor_task 'shell', 'Running bundle install, this may take a while'
          run_from @active_path, 'bundle install'

          git_commit 'Add gem lock file'
        end

        def bundle_binstubs
          log_thor_task 'shell', 'Running bundle binstubs for a few gems'
          run_from @active_path, 'bundle binstubs whenever puma sidekiq'

          git_commit 'Add binstubs for the important gems'
        end

        def spring_binstub
          log_thor_task 'shell', 'Running spring binstub'
          run_from @active_path, 'bundle exec spring binstub --all'

          git_commit 'Springify all of the bins'
        end

        def run_rake(command)
          log_thor_task 'shell', 'Running rake commands'

          run_from @active_path, "bundle exec rake #{command}"
        end

        def create_and_migrate_database
          run_rake 'db:create:all db:migrate'
          git_commit 'Add the database schema file'
        end

        private

        def exit_if_cannot_rails
          log_thor_task 'shell', 'Checking for rails'

          has_rails = run('which rails', capture: true)

          log_error 'error', 'Cannot access rails', 'question', 'Are you sure you have rails setup correctly?', true do
            log_status_bottom 'tip', 'You can install it by running `gem install rails`', :white
          end if has_rails.empty?

          exit 1 if has_rails.empty?
        end

        def exit_if_exists
          log_thor_task 'shell', 'Checking if a file or directory already exists'

          if Dir.exist?(@active_path) || File.exist?(@active_path)
            log_error 'error', 'A file or directory already exists at this location', 'path', @active_path
            exit 1
          end
        end
      end
    end
  end
end