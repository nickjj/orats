module Orats
  module Shell
    def run_from(path, command)
      run "cd #{path} && #{command} && cd -"
    end

    def cd_inside(path, &block)
      run "cd #{path}"
      yield
      run 'cd -'
    end

    def log_message(type, message)
      puts
      say_status  type, "#{message}...", :yellow
      puts        '-'*80, ''; sleep 0.25
    end

    def git_commit(message)
      run_from @active_path, "git add . && git commit -m '#{message}'"
    end

    def gsub_postgres_info
      log_message 'root', 'Changing the postgres information'

      gsub_file "#{@active_path}/.env", ': localhost', ": #{@options[:pg_location]}"
      gsub_file "#{@active_path}/.env", ': postgres', ": #{@options[:pg_username]}"
      gsub_file "#{@active_path}/.env", ': supersecrets', ": #{@options[:pg_password]}"
    end

    def run_rake(command)
      log_message 'shell', 'Running rake commands'

      run_from @active_path, "bundle exec rake #{command}"
    end

    def bundle_install
      log_message 'shell', 'Running bundle install, this may take a while'

      run_from @active_path, 'bundle install'
    end

    def nuke_redis
      log_message 'root', 'Removing redis keys'

      run "redis-cli KEYS '#{active_project}:*' | xargs --delim='\n' redis-cli DEL"
    end

    def nuke_directory
      log_message 'root', 'Deleting directory'

      run "rm -rf #{@active_path}"
    end

    def exit_if_exists
      log_message 'shell', 'Checking if a file or directory already exists'

      if Dir.exist?(@active_path) || File.exist?(@active_path)
        puts
        say_status  'aborting', "\e[1mA file or directory already exists at this location:\e[0m", :red
        say_status  'location', @active_path, :yellow
        puts        '-'*80
        puts

        exit 1
      end
    end

    def exit_if_cannot_cook
      log_message 'shell', 'Checking for the cookbook system dependencies'

      has_knife = run('which knife', capture: true)
      has_berks = run('which berks', capture: true)

      dependency_error 'Cannot access knife',
                       'Are you sure you have chef setup correctly?',
                       'http://www.getchef.com/chef/install/`' if has_knife.empty?


      dependency_error 'Cannot access berkshelf',
                       'Are you sure you have berkshelf installed correctly?',
                       'You can install it by running `gem install berkshelf`' if has_berks.empty?
    end

    def exit_if_cannot_rails
      log_message 'shell', 'Checking for rails'

      has_rails = run('which rails', capture: true)

      dependency_error 'Cannot access rails',
                       'Are you sure you have rails setup correctly?',
                       'You can install it by running `gem install rails`' if has_rails.empty?
    end

    def dependency_error(message, question, answer)
      puts
      say_status  'error', "\e[1m#{message}\e[0m", :red
      say_status  'question', question, :yellow
      say_status  'answer', answer, :cyan
      puts        '-'*80
      puts

      exit 1
    end

    def rails_template(command, flags = '', &block)
      exit_if_cannot_rails
      exit_if_exists unless flags.index(/--skip /)

      run "rails new #{@active_path} #{flags}--skip-bundle --template #{File.expand_path File.dirname(__FILE__)}/templates/#{command}.rb"
      yield if block_given?
    end

    def cook_app(app_path)
      exit_if_cannot_cook

      @active_path = app_path
      rails_template 'cook'
    end
  end
end