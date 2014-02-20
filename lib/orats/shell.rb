module Orats
  module Shell
    def run_from(path, command)
      run "cd #{path} && #{command} && cd -"
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

    def nuke_warning
      puts
      say_status  'nuke', "\e[1mYou are about to permanently delete this directory:\e[0m", :red
      say_status  'path', "#{File.expand_path(@app_name)}", :yellow
      puts
    end

    def rails_directories
      rails_gemfiles = run("find #{@active_path} -type f -name Gemfile | xargs grep -lE \"gem 'rails'|gem \\\"rails\\\"\"", capture: true)
      gemfile_paths = rails_gemfiles.split("\n")

      gemfile_paths.map { |gemfile| File.dirname(gemfile) }
    end

    def nuke_data_details_warning
      rails_projects = []

      rails_directories.each do |rails_dir|
        rails_projects << project_from_path(rails_dir)
      end

      project_names = rails_projects.join(', ')

      puts
      say_status  'nuke', "\e[1mYou are about to permanently delete all postgres databases for:\e[0m", :red
      say_status  'databases', project_names, :yellow
      puts
      say_status  'nuke', "\e[1mYou are about to permanently delete all redis namespaces for:\e[0m", :red
      say_status  'namespace', project_names, :yellow
      puts
    end

    def nuke_data
      rails_directories.each do |directory|
        log_message 'root', 'Removing postgres databases'
        run_from directory, 'bundle exec rake db:drop:all'
        nuke_redis project_from_path(directory)
      end
    end

    def can_cook?
      log_message 'shell', 'Checking for the cookbook system dependencies'

       has_knife = run('which knife', capture: true)
       has_berks = run('which berks', capture: true)

       dependency_error 'Cannot access knife',
                        'Are you sure you have chef setup correctly?',
                        'http://www.getchef.com/chef/install/`' if has_knife.empty?

       dependency_error 'Cannot access berkshelf',
                        'Are you sure you have berkshelf installed correctly?',
                        'You can install it by running `gem install berkshelf`' if has_berks.empty?

       !has_knife.empty? && !has_berks.empty?
    end

    def rails_template(command, flags = '')
      exit_if_cannot_rails
      exit_if_exists unless flags.index(/--skip/)

      run "rails new #{@active_path} #{flags} --skip-bundle --template #{File.expand_path File.dirname(__FILE__)}/templates/#{command}.rb"
      yield if block_given?
    end

    def cook_app(app_path)
      return unless can_cook?

      @active_path = app_path
      rails_template 'cook'
    end

    private

      def nuke_redis(namespace)
        log_message 'root', 'Removing redis keys'

        run "redis-cli KEYS '#{namespace}:*' | xargs --delim='\n' redis-cli DEL"
      end

      def nuke_directory
        log_message 'root', 'Deleting directory'

        run "rm -rf #{@active_path}"
      end

      def dependency_error(message, question, answer)
        puts
        say_status  'error', "\e[1m#{message}\e[0m", :red
        say_status  'question', question, :yellow
        say_status  'answer', answer, :cyan
        puts        '-'*80
        puts
      end

      def exit_if_cannot_rails
        log_message 'shell', 'Checking for rails'

        has_rails = run('which rails', capture: true)

        dependency_error 'Cannot access rails',
                         'Are you sure you have rails setup correctly?',
                         'You can install it by running `gem install rails`' if has_rails.empty?

        exit 1 if has_rails.empty?
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

      def project_from_path(path)
        path.split('/').last
      end
  end
end