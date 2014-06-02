require 'securerandom'

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

      gsub_file "#{@active_path}/.env", 'DATABASE_HOST: localhost', "DATABASE_HOST: #{@options[:pg_location]}"
      gsub_file "#{@active_path}/.env", ': postgres', ": #{@options[:pg_username]}"
      gsub_file "#{@active_path}/.env", ': supersecrets', ": #{@options[:pg_password]}"
    end

    def gsub_redis_info
      log_message 'root', 'Adding the redis password'

      gsub_file "#{@active_path}/config/initializers/sidekiq.rb", '//', "//:#{ENV['#{@app_name.upcase}_CACHE_PASSWORD']}@"
      gsub_file "#{@active_path}/.env", 'HE_PASSWORD: ', "HE_PASSWORD: #{@options[:redis_password]}"
      gsub_file "#{@active_path}/.env", 'CACHE_HOST: localhost', "CACHE_HOST: #{@options[:redis_location]}"
      gsub_file "#{@active_path}/config/application.rb", '# pass', 'pass'
    end

    def gsub_project_path
      log_message 'root', 'Changing the project path'

      gsub_file "#{@active_path}/.env", ': /full/path/to/your/project', ": #{File.expand_path(@active_path)}"
    end

    def run_rake(command)
      log_message 'shell', 'Running rake commands'

      run_from @active_path, "bundle exec rake #{command}"
    end

    def bundle_install
      log_message 'shell', 'Running bundle install, this may take a while'

      run_from @active_path, 'bundle install'
    end

    def bundle_binstubs
      log_message 'shell', 'Running bundle binstubs for a few gems'

      run_from @active_path, 'bundle binstubs whenever puma sidekiq'
    end

    def spring_binstub
      log_message 'shell', 'Running spring binstub'

      run_from @active_path, 'bundle exec spring binstub --all'
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
        rails_projects << File.basename(rails_dir)
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
        nuke_redis File.basename(directory)
      end
    end

    def can_play?
      log_message 'shell', 'Checking for the ansible binary'

       has_ansible = run('which ansible', capture: true)

       dependency_error 'Cannot access ansible',
                        'Are you sure you have ansible setup correctly?',
                        'http://docs.ansible.com/intro_installation.html`' if has_ansible.empty?

       !has_ansible.empty?
    end

    def rails_template(command, flags = '')
      exit_if_cannot_rails
      exit_if_exists unless flags.index(/--skip/)

      run "rails new #{@active_path} #{flags} --skip-bundle --template #{File.expand_path File.dirname(__FILE__)}/templates/#{command}.rb"
      yield if block_given?
    end

    def play_app(path)
      return unless can_play?

      @active_path = path
      rails_template 'play'
    end

    def ansible_init(path)
      log_message 'shell', 'Creating ansible inventory'
      run "mkdir #{path}/inventory"
      run "mkdir #{path}/inventory/group_vars"
      copy_from_includes 'inventory/hosts', path
      copy_from_includes 'inventory/group_vars/all.yml', path

      secrets_path = "#{path}/secrets"
      log_message 'shell', 'Creating ansible secrets'
      run "mkdir #{secrets_path}"

      save_secret_string "#{secrets_path}/postgres_password"

      if @options[:redis_password].empty?
        run "touch #{secrets_path}/redis_password"
      else
        save_secret_string "#{secrets_path}/redis_password"
        gsub_file "#{path}/inventory/group_vars/all.yml", 'redis_password: false', 'redis_password: true'
      end
      
      save_secret_string "#{secrets_path}/mail_password"
      save_secret_string "#{secrets_path}/rails_token"
      save_secret_string "#{secrets_path}/devise_token"
      save_secret_string "#{secrets_path}/devise_pepper_token"

      log_message 'shell', 'Modifying secrets path in group_vars/all.yml'
      gsub_file "#{path}/inventory/group_vars/all.yml", '~/tmp/testproj/secrets/', File.expand_path(secrets_path)

      log_message 'shell', 'Modifying the place holder app name in group_vars/all.yml'
      gsub_file "#{path}/inventory/group_vars/all.yml", 'testproj', File.basename(path)
      gsub_file "#{path}/inventory/group_vars/all.yml", 'TESTPROJ', File.basename(path).upcase

      log_message 'shell', 'Creating ssh keypair'
      run "ssh-keygen -t rsa -P '' -f #{secrets_path}/id_rsa"

      log_message 'shell', 'Creating self signed ssl certificates'
      run "openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 -subj '/C=US/ST=Foo/L=Bar/O=Baz/CN=qux.com' -keyout #{secrets_path}/sslkey.key -out #{secrets_path}/sslcert.crt"

      log_message 'shell', 'Creating monit pem file'
      run "openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 -subj '/C=US/ST=Foo/L=Bar/O=Baz/CN=qux.com' -keyout #{secrets_path}/monit.pem -out #{secrets_path}/monit.pem && openssl gendh 512 >> #{secrets_path}/monit.pem"

      install_role_dependencies unless @options[:skip_galaxy]
    end

    private

      def install_role_dependencies
        log_message 'shell', 'Updating ansible roles from the galaxy'
        roles_formatted = IO.read("#{File.expand_path File.dirname(__FILE__)}/templates/includes/Galaxyfile")
                            .gsub(/\r?\n/, ' ')

        galaxy_install = "ansible-galaxy install #{roles_formatted} --force"
        galaxy_out = run(galaxy_install, capture: true)

        if galaxy_out.include?('you do not have permission')
          if @options[:sudo_password].empty?
            sudo_galaxy_command = 'sudo'
          else
            sudo_galaxy_command = "echo #{@options[:sudo_password]} | sudo -S"
          end

          run("#{sudo_galaxy_command} #{galaxy_install}")
        end
      end

      def save_secret_string(file)
        File.open(file, 'w+') { |f| f.write(SecureRandom.hex(64)) }
      end

      def copy_from_includes(file, destination_root_path)
        base_path = "#{File.expand_path File.dirname(__FILE__)}/templates/includes"

        log_message 'shell', "Creating #{file}"
        run "cp #{base_path}/#{file} #{destination_root_path}/#{file}"
      end

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
  end
end