module Orats
  module Commands
    module New
      # helper functions for the new::exec class
      module Rails
        def check_exit_conditions
          exit_if_path_exists
          exit_if_invalid_template
          exit_if_invalid_system
          exit_if_database_exists
        end

        def rails_template(command, flags = '')
          orats_template = "--template #{base_path}/templates/#{command}.rb"

          run "rails new #{@target_path} #{flags} --skip-bundle " + \
              " #{orats_template unless command.empty?}"

          yield if block_given?
        end

        def orats_rails_template
          rails_template @options[:template], '--skip ' do
            migrate_and_seed_database
          end
        end

        def custom_rails_template
          task 'Add custom template'

          if @options[:custom].include('://')
            url_to_string(@options[:custom])
          else
            file_to_string(@options[:custom])
          end

          rails_template '', "--skip --template #{@options[:custom]}"
        end

        def rails_template_actions
          gsub_postgres_info
          gsub_redis_info
          gsub_readme

          bundle_install
          bundle_binstubs
          spring_binstub

          create_and_migrate_database
          generate_home_page
          generate_favicons
        end

        def gsub_postgres_info
          task 'Update the DATABASE_URL'

          unless @options[:pg_password].empty?
            gsub_file "#{@target_path}/.env", 'db_user',
                      "db_user:#{@options[:pg_password]}"
          end

          gsub_file "#{@target_path}/.env", 'db_location',
                    @options[:pg_location]
          gsub_file "#{@target_path}/.env", 'db_port', @options[:pg_port]
          gsub_file "#{@target_path}/.env", 'db_user', @options[:pg_username]

          commit 'Update the DATABASE_URL'
        end

        def gsub_redis_info
          task 'Update the redis connection details'

          unless @options[:redis_password].empty?
            gsub_file "#{@target_path}/.env", '//',
                      "//#{@options[:redis_password]}@"
          end

          gsub_file "#{@target_path}/.env", 'cache_location',
                    @options[:redis_location]
          gsub_file "#{@target_path}/.env", 'cache_port', @options[:redis_port]

          commit 'Update the CACHE_URL'
        end

        def gsub_app_path
          task 'Update the app path'

          gsub_file "#{@target_path}/.env", ": '/tmp/yourapp'",
                    ": '#{File.expand_path(@target_path)}'"

          commit 'Update the app path'
        end

        def gsub_readme
          task 'Update the readme'

          gsub_file "#{@target_path}/README.md", 'VERSION', VERSION

          commit 'Update the readme'
        end

        def bundle_install
          task 'Run bundle install, this may take a while'
          run_from @target_path, 'bundle install'

          commit 'Add Gemfile.lock'
        end

        def bundle_binstubs
          task 'Run bundle binstubs for a few gems'
          run_from @target_path, 'bundle binstubs whenever puma sidekiq backup'

          commit 'Add binstubs for the important gems'
        end

        def spring_binstub
          task 'Run spring binstub'
          run_from @target_path, 'bundle exec spring binstub --all'

          commit 'Add spring binstubs for all of the bins'
        end

        def generate_home_page
          kill_spring_servers

          task 'Add pages controller with static page'
          run_from @target_path, 'bundle exec rails g controller Pages home'

          gsub_home_page
          copy_home_page_views

          commit 'Add pages controller with home page'
        end

        def generate_favicons
          run_rake 'orats:favicons'

          commit 'Add favicons'
        end

        def create_and_migrate_database
          task 'Create and migrate the database'

          create_database
          run_rake 'db:migrate'

          commit 'Add the database schema file'
        end

        def migrate_and_seed_database
          run_rake 'db:migrate db:seed'

          commit 'Update the database schema file'
        end

        def template_exist?(template)
          Exec::AVAILABLE_TEMPLATES.include?(template.to_sym)
        end

        private

        def gsub_home_page
          gsub_file "#{@target_path}/config/routes.rb",
                    "  # root 'welcome#index'", "  root 'pages#home'"
          gsub_file "#{@target_path}/config/routes.rb",
                    "  get 'pages/home'\n\n", ''

          gsub_file "#{@target_path}/test/controllers/pages_controller_" + \
                    'test.rb', '"should get home"', "'expect home page'"
        end

        def copy_home_page_views
          run_from @target_path, 'rm app/views/pages/home.html.erb'

          orats_to_local 'new/rails/app/views/pages/home.html.erb',
                         "#{@target_path}/app/views/pages/home.html.erb"

          gsub_file "#{@target_path}/app/views/pages/home.html.erb",
                    'vVERSION', VERSION
        end

        def exit_if_invalid_template
          template = @options[:template] || ''
          task 'Check if template exists'

          return if template.empty? || template_exist?(template)

          error 'Cannot find template',
                "'#{template}' is not a valid template name"

          available_templates
          exit 1
        end

        def kill_spring_servers
          # rails generators will lock up if a spring server is running,
          # so kill them all before continuing
          system 'pkill -f spring'
        end
      end
    end
  end
end
