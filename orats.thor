module Orats
  require 'socket'
  require 'timeout'

  class App < Thor
    include Thor::Actions

    attr_accessor :app_name

    class_option :postgres_location, default: 'localhost'
    class_option :postgres_username, default: 'postgres'
    class_option :postgres_password, required: true

    desc 'base APP_NAME', 'Create a new rails application using the base template.'
    def base(app_name)
      @app_name = app_name

      puts invoked?

      run "rails new #{@app_name} --skip-bundle --template https://raw.github.com/nickjj/orats/master/templates/base.rb"

      command_line_tasks do
        gsub_postgres_info options
        git_commit 'Change the postgres information'

        bundle_install
        git_commit 'Add gem lock file'

        run_rake 'db:create:all db:migrate db:test:prepare'
        git_commit 'Add the schema.rb file'

        start_server unless invoked?
      end
    end

    desc 'auth APP_NAME', 'Create a new rails application with authentication/authorization.'
    def auth(app_name)
      @app_name = app_name

      invoke :base

      run "rails new #{@app_name} --skip --skip-bundle --template https://raw.github.com/nickjj/orats/master/templates/authentication-and-authorization.rb"

      command_line_tasks do
        run_rake 'db:migrate db:seed'

        start_server
      end
    end

    desc 'nuke APP_NAME', 'Delete an application and optionally its postgres databases and redis namespace.'
    option :postgres_password, default: ''
    option :delete_data, type: :boolean, default: true
    def nuke(app_name)
      @app_name = app_name

      puts
      say_status  'nuke', "\e[1mYou are about to permanently delete this directory:\e[0m", :red
      say_status  'path', "#{File.expand_path(app_name)}", :yellow

      if options[:delete_data]
        puts
        say_status  'nuke', "\e[1mYou are about to permanently delete these postgres databases:\e[0m", :red
        say_status  'databases', "#{app_name_only} and #{app_name_only}_test", :yellow
        puts
        say_status  'nuke', "\e[1mYou are about to permanently delete this redis namespace:\e[0m", :red
        say_status  'namespace', app_name_only, :yellow
      end
      puts

      confirmed_to_delete = yes?('Are you sure? (y/N)', :cyan)

      if confirmed_to_delete
        command_line_tasks do
          if options[:delete_data]
            run_rake 'db:drop:all'
            nuke_redis
          end

          puts
          say_status  'shell', 'Deleting directory...', :yellow
          puts        '-'*80, ''; sleep 0.25

          run "rm -rf #{@app_name}"
        end
      end
    end

    private

      def invoked?
        caller_locations(0).any? { |backtrace| backtrace.label == 'invoke' }
      end

      def app_name_only
        @app_name.split('/').last
      end

      def git_commit(message)
        run_with_cd "git add . && git commit -m '#{message}'"
      end

      def run_with_cd(command)
        run "cd #{@app_name} && #{command} && cd -"
      end

      def command_line_tasks(&block)
        yield
      end

      def run_rake(command)
        puts
        say_status  'shell', 'Running rake commands...', :yellow
        puts        '-'*80, ''; sleep 0.25

        run_with_cd "bundle exec rake #{command}"
      end

      def bundle_install
        puts
        say_status  'shell', 'Running bundle install, this may take a while...', :yellow
        puts        '-'*80, ''; sleep 0.25

        run "cd #{@app_name} && bundle install && cd -"
      end

      def gsub_postgres_info(options)
        puts
        say_status  'root', 'Changing the postgres information...', :yellow
        puts        '-'*80, ''; sleep 0.25

        gsub_file "#{@app_name}/.env", ': localhost', ": #{options[:postgres_location]}"
        gsub_file "#{@app_name}/.env", ': postgres', ": #{options[:postgres_username]}"
        gsub_file "#{@app_name}/.env", ': supersecrets', ": #{options[:postgres_password]}"
      end

      def nuke_redis
        puts
        say_status  'shell', 'Removing redis keys...', :yellow
        puts        '-'*80, ''; sleep 0.25

        run "redis-cli KEYS '#{app_name_only}:*' | xargs --delim='\n' redis-cli DEL"
      end

      def start_server
        puts  '', '='*80
        say_status  'action', "\e[1mStarting server with the following commands:\e[0m", :cyan
        say_status  'command', "cd #{app_name}", :magenta
        say_status  'command', 'bundle exec foreman start', :magenta
        puts  '='*80, ''

        attempt_to_start_server
      end

      def attempt_to_start_server
        while port_taken? do
          puts
          say_status  'error', "\e[1mAnother application is using port 3000\n\e[0m", :red
          puts        '-'*80

          exit 1 if no?('Would you like to try running the server again? (y/N)', :cyan)
        end

        puts
        run_with_cd 'bundle exec foreman start'
      end

      def port_taken?
        begin
          Timeout::timeout(5) do
            begin
              s = TCPSocket.new('localhost', 3000)
              s.close

              return true
            rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
              return false
            end
          end
        rescue Timeout::Error
          false
        end

        false
      end
  end
end