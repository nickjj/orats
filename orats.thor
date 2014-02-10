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

      run "rails new #{@app_name} --skip-bundle --template https://raw.github.com/nickjj/orats/master/templates/base.rb"

      gsub_postgres_info options
      git_commit 'Change the postgres information'

      bundle_install
      git_commit 'Add gem lock file'

      run_rake 'db:create:all db:migrate db:test:prepare'
      git_commit 'Add the database schema file'

      start_server
    end

    desc 'auth APP_NAME', 'Create a new rails application with authentication/authorization.'
    def auth(app_name)
      @app_name = app_name

      invoke :base

      run "rails new #{@app_name} --skip --skip-bundle --template https://raw.github.com/nickjj/orats/master/templates/authentication-and-authorization.rb"

      run_rake 'db:migrate db:seed'

      start_server
    end

    desc 'nuke APP_NAME', 'Delete an application and optionally its postgres databases and redis namespace.'
    option :postgres_password, required: false
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
        if options[:delete_data]
          run_rake 'db:drop:all'
          nuke_redis
          nuke_directory
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

      def log_message(type, message)
        puts
        say_status  type, "#{message}...", :yellow
        puts        '-'*80, ''; sleep 0.25
      end

      def run_rake(command)
        log_message 'shell', 'Running rake commands'

        run_with_cd "bundle exec rake #{command}"
      end

      def bundle_install
        log_message 'shell', 'Running bundle install, this may take a while'

        run "cd #{@app_name} && bundle install && cd -"
      end

      def gsub_postgres_info(options)
        log_message 'root', 'Changing the postgres information'

        gsub_file "#{@app_name}/.env", ': localhost', ": #{options[:postgres_location]}"
        gsub_file "#{@app_name}/.env", ': postgres', ": #{options[:postgres_username]}"
        gsub_file "#{@app_name}/.env", ': supersecrets', ": #{options[:postgres_password]}"
      end

      def nuke_redis
        log_message 'root', 'Removing redis keys'

        run "redis-cli KEYS '#{app_name_only}:*' | xargs --delim='\n' redis-cli DEL"
      end

      def nuke_directory
        log_message 'root', 'Deleting directory'

        run "rm -rf #{@app_name}"
      end

      def start_server
        unless invoked?
          puts  '', '='*80
          say_status  'action', "\e[1mStarting server with the following commands:\e[0m", :cyan
          say_status  'command', "cd #{app_name}", :magenta
          say_status  'command', 'bundle exec foreman start', :magenta
          puts  '='*80, ''

          attempt_to_start_server
        end
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