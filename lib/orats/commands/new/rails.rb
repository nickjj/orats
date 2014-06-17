module Orats
  module Commands
    module New
      module Rails
        def check_exit_conditions
          exit_if_process :not_found, 'rails', 'git'
          exit_if_process :not_running, 'postgres', 'redis'
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

        def gsub_readme
          log_task 'Update the readme'
          gsub_file "#{@active_path}/README.md", 'VERSION', VERSION

          git_commit 'Update the version'
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

        def generate_home_page
          log_task 'Add pages controller with static page'
          run_from @active_path, 'bundle exec rails g controller Pages home'

          gsub_file "#{@active_path}/config/routes.rb", "  # root 'welcome#index'" do
            <<-S
  root 'pages#home'
            S
          end
          gsub_file "#{@active_path}/config/routes.rb", "  get 'pages/home'\n\n", ''

          gsub_file "#{@active_path}/test/controllers/pages_controller_test.rb",
                    '"should get home"', "'expect home page'"
          gsub_file "#{@active_path}/app/views/pages/home.html.erb", /.*\n/, ''
          append_file "#{@active_path}/app/views/pages/home.html.erb" do
            <<-S
<%
  title 'Welcome to Ruby on Rails'
  meta_description '...'
  heading 'Welcome to Ruby on Rails'
%>

<div class="row">
  <div class="col-sm-9">
    <p class="lead">
      You have successfully generated a project with <%= link_to 'orats', 'https://github.com/nickjj/orats' %> v#{VERSION}.
    </p>

    <hr />

    <p>
      <%= image_tag 'https://badge.fury.io/rb/orats.png', alt: 'Gem badge' %> is the latest version of orats.
    </p>

    <hr />

    <h3>Custom rake tasks</h3>
    <pre>
      <code>
      # backup the database to S3 or any other location
      bundle exec rake orats:backup

      # generate a new set of favicons to the public directory
      bundle exec rake orats:favicons
      </code>
    </pre>

    <hr />

    <h3>Trying to figure out what to do next?</h3>
    <p>
      Visit the wiki guide for <%= link_to 'what to look at after making a new project', 'https://github.com/nickjj/orats/wiki/What-to-look-at-after-making-a-new-project' %>.
    </p>

    <hr />

    <h3>Looking to deploy your application?</h3>
    <p>
      Visit the wiki guide for <%= link_to 'get your application on a server ', 'https://github.com/nickjj/orats/wiki/Get-your-application-on-a-server' %>.
    </p>

    <hr />

    <h3>Want to get rid of the pages controller?</h3>
    <p>
      No problem, just follow these steps:
      <ul>
        <li>
          Run <code>bundle exec rails d controller Pages</code>
        </li>
        <li>
          Remove the root route from <code>config/routes.rb</code>
        </li>
        <li>
          Remove the link in the navigation partial at <code>app/views/layouts/_navigation_links.html.erb</code>
        </li>
        <li>
          Restart the server
        </li>
      </ul>
    </p>
  </div>

  <div class="col-sm-3">
    <%= image_tag '/apple-touch-icon-228x228-precomposed.png', size: '228x228', alt: 'A ruby image I found on Google' %>
  </div>
</div>
            S
          end
          git_commit 'Add pages controller with home page'
        end

        def generate_favicons
          log_task 'Add favicons'
          run_rake 'orats:favicons'
          git_commit 'Add favicons'
        end

        def create_and_migrate_database
          run_rake 'db:create:all db:migrate'
          git_commit 'Add the database schema file'
        end
      end
    end
  end
end