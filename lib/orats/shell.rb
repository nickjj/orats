require 'securerandom'
require 'open-uri'

module Orats
  module Shell
    def run_from(path, command)
      run "cd #{path} && #{command} && cd -"
    end

    def git_commit(message)
      run_from @active_path, "git add -A && git commit -m '#{message}'"
    end

    def gsub_postgres_info
      log_thor_task 'root', 'Changing the postgres information'
      gsub_file "#{@active_path}/.env", 'DATABASE_HOST: localhost', "DATABASE_HOST: #{@options[:pg_location]}"
      gsub_file "#{@active_path}/.env", ': postgres', ": #{@options[:pg_username]}"
      gsub_file "#{@active_path}/.env", ': supersecrets', ": #{@options[:pg_password]}"
    end

    def gsub_redis_info
      log_thor_task 'root', 'Adding the redis password'
      gsub_file "#{@active_path}/config/initializers/sidekiq.rb", '//', "//:#{ENV['CACHE_PASSWORD']}@"
      gsub_file "#{@active_path}/.env", 'HE_PASSWORD: ', "HE_PASSWORD: #{@options[:redis_password]}"
      gsub_file "#{@active_path}/.env", 'CACHE_HOST: localhost', "CACHE_HOST: #{@options[:redis_location]}"
      gsub_file "#{@active_path}/config/application.rb", '# pass', 'pass'
    end

    def gsub_project_path
      log_thor_task 'root', 'Changing the project path'
      gsub_file "#{@active_path}/.env", ': /full/path/to/your/project', ": #{File.expand_path(@active_path)}"
    end

    def run_rake(command)
      log_thor_task 'shell', 'Running rake commands'

      run_from @active_path, "bundle exec rake #{command}"
    end

    def bundle_install
      log_thor_task 'shell', 'Running bundle install, this may take a while'
      run_from @active_path, 'bundle install'
    end

    def bundle_binstubs
      log_thor_task 'shell', 'Running bundle binstubs for a few gems'
      run_from @active_path, 'bundle binstubs whenever puma sidekiq'
    end

    def spring_binstub
      log_thor_task 'shell', 'Running spring binstub'
      run_from @active_path, 'bundle exec spring binstub --all'
    end

    def nuke_warning
      log_error 'nuke', 'You are about to permanently delete this directory',
                'path', File.expand_path(@target_path)
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

      log_error 'nuke', 'You are about to permanently delete all postgres databases for',
                'databases', project_names, true

      log_error 'nuke', 'You are about to permanently delete all redis namespaces for',
                'namespace', project_names
    end

    def nuke_data
      rails_directories.each do |directory|
        log_thor_task 'root', 'Removing postgres databases'
        run_from directory, 'bundle exec rake db:drop:all'

        nuke_redis File.basename(directory)
      end
    end

    def can_play?
      log_thor_task 'shell', 'Checking for the ansible binary'

      has_ansible = run('which ansible', capture: true)

      log_error 'error', 'Cannot access ansible', 'question', 'Are you sure you have ansible setup correctly?', true do
        log_status_bottom 'tip', 'http://docs.ansible.com/intro_installation.html', :white
      end if has_ansible.empty?

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
      log_thor_task 'shell', 'Creating ansible inventory'
      run "mkdir #{path}/inventory"
      run "mkdir #{path}/inventory/group_vars"
      copy_from_includes 'inventory/hosts', path
      copy_from_includes 'inventory/group_vars/all.yml', path

      secrets_path = "#{path}/secrets"
      log_thor_task 'shell', 'Creating ansible secrets'
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

      log_thor_task 'shell', 'Modifying secrets path in group_vars/all.yml'
      gsub_file "#{path}/inventory/group_vars/all.yml", '~/tmp/testproj/secrets/', File.expand_path(secrets_path)

      log_thor_task 'shell', 'Modifying the place holder app name in group_vars/all.yml'
      gsub_file "#{path}/inventory/group_vars/all.yml", 'testproj', File.basename(path)

      log_thor_task 'shell', 'Creating ssh keypair'
      run "ssh-keygen -t rsa -P '' -f #{secrets_path}/id_rsa"

      log_thor_task 'shell', 'Creating self signed ssl certificates'
      run create_rsa_certificate(secrets_path, 'sslkey.key', 'sslcert.crt')

      log_thor_task 'shell', 'Creating monit pem file'
      run "#{create_rsa_certificate(secrets_path, 'monit.pem', 'monit.pem')} && openssl gendh 512 >> #{secrets_path}/monit.pem"

      install_role_dependencies unless @options[:skip_galaxy]
    end

    def outdated_init
      latest_gem_version = compare_gem_version

      github_repo = "https://raw.githubusercontent.com/nickjj/orats/#{latest_gem_version}/lib/orats"

      galaxy_url = "#{github_repo}/templates/includes/Galaxyfile"
      playbook_url = "#{github_repo}/templates/play.rb"
      inventory_url = "#{github_repo}/templates/includes/inventory/group_vars/all.yml"

      remote_galaxy_contents = url_to_string(galaxy_url)
      remote_playbook_contents = url_to_string(playbook_url)
      remote_inventory_contents = url_to_string(inventory_url)

      compare_remote_role_version_to_local remote_galaxy_contents

      local_playbook = compare_remote_to_local('playbook',
                              'roles',
                              playbook_file_stats(remote_playbook_contents),
                              playbook_file_stats(IO.read(playbook_file_path)))

      local_inventory = compare_remote_to_local('inventory',
                              'variables',
                              inventory_file_stats(remote_inventory_contents),
                              inventory_file_stats(IO.read(inventory_file_path)))

      unless @options[:playbook].empty?
        compare_user_to_local('playbook', 'roles', @options[:playbook], local_playbook) do
          playbook_file_stats IO.read(@options[:playbook])
        end
      end

      unless @options[:inventory].empty?
        compare_user_to_local('inventory', 'variables', @options[:inventory], local_inventory) do
          inventory_file_stats IO.read(@options[:inventory])
        end
      end
    end

    private

      def inventory_file_stats(file)
        # pluck out all of the values contained with {{ }}
        ansible_variable_list = file.scan(/\{\{([^{{}}]*)\}\}/)

        # remove the leading space
        ansible_variable_list.map! { |line| line.first[0] = '' }

        # match every line that is not a comment and contains a colon
        inventory_variable_list = file.scan(/^[^#].*:/)

        inventory_variable_list.map! do |line|
          # only strip lines that need it
          line.strip! if line.include?(' ') || line.include?("\n")

          # get rid of the trailing colon
          line.chomp(':')

          # if a value of a certain variable has a colon then the regex
          # picks this up as a match. only take the variable name
          # if this happens to occur
          line.split(':').first if line.include?(':')
        end

        (ansible_variable_list + inventory_variable_list).uniq
      end

      def playbook_file_stats(file)
        # match every line that is not a comment and has a role defined
        roles_list = file.scan(/^.*role:.*/)

        roles_list.map! do |line|
          # only strip lines that need it
          line.strip! if line.include?(' ') || line.include?("\n")

          role_parts = line.split('role:')

          line = role_parts[1]

          if line.include?(',')
            line = line.split(',').first
          end

          line.strip! if line.include?(' ')
        end

        roles_list.reject! { |line| line.start_with?('#') }

        roles_list.uniq
      end

      def compare_gem_version
        latest_gem_contents = `gem list orats --remote`.split.last

        if latest_gem_contents.include?('ERROR')
          log_error 'error', 'Error running `gem list orats --remote`',
                    'message', 'Chances are their API is down, try again soon'
          exit 1
        end

        latest_gem_version = "v#{latest_gem_contents.split.first[1...-1]}"

        log_remote_info 'gem', 'Comparing this version of orats to the latest orats version',
                        'version', "Latest: #{latest_gem_version}, Yours: v#{VERSION}"

        latest_gem_version
      end

      def compare_remote_role_version_to_local(remote_galaxy_contents)
        remote_galaxy_list = remote_galaxy_contents.split
        local_galaxy_contents = IO.read(galaxy_file_path)
        local_galaxy_list = local_galaxy_contents.split

        galaxy_difference = remote_galaxy_list - local_galaxy_list

        local_role_count = local_galaxy_list.size
        different_roles = galaxy_difference.size

        log_status_top 'roles', "Comparing this version of orats' roles to the latest version:", :green

        if different_roles == 0
          log_status_bottom 'message', "All #{local_role_count} roles are up to date", :yellow
        else
          log_status_bottom 'message', "There are #{different_roles} differences", :yellow

          galaxy_difference.each do |role_line|
            name = role_line.split(',').first
            status = 'outdated'
            color = :yellow

            unless local_galaxy_contents.include?(name)
              status = 'missing'
              color = :red
            end

            log_status_bottom status, name, color
          end

          log_results 'The latest version of orats may benefit you', 'Check github to see if the changes interest you'
        end
      end

      def compare_remote_to_local(label, keyword, remote_list, local_list)
        list_difference = remote_list - local_list

        remote_count = list_difference.size

        log_remote_info label, "Comparing this version of orats' #{label} to the latest version",
                        'file', label == 'playbook' ? 'site.yml' : 'all.yml'

        list_difference.each do |line|
          log_status_bottom 'missing', line, :red unless local_list.include?(line)
        end

        if remote_count > 0
          log_results "#{remote_count} new #{keyword} are available", 'You may benefit from upgrading to the latest orats'
        else
          log_results 'Everything appears to be in order', "No missing #{keyword} were found"
        end

        local_list
      end

      def compare_user_to_local(label, keyword, user_path, local_list)
        if File.exist?(user_path) && File.file?(user_path)
          user_list = yield

          just_file_name = user_path.split('/').last

          log_local_info label, "Comparing this version of orats' #{label} to #{just_file_name}",
                         'path', user_path

          missing_count = log_unmatched local_list, user_list, 'missing', :red
          extra_count = log_unmatched user_list, local_list, 'extra', :yellow

          if missing_count > 0
            log_results "#{missing_count} #{keyword} are missing", "Your ansible run will likely fail with this #{label}"
          else
            log_results 'Everything appears to be in order', "No missing #{keyword} were found"
          end

          if extra_count > 0
            log_results "#{extra_count} extra #{keyword} were detected:", "No problem but remember to add them to a future #{keyword}"
          else
            log_results "No extra #{keyword} were found:", "Extra #{keyword} are fine but you have none"
          end
        else
          log_status_top label, "Comparing this version of orats' #{label} to ???:", :blue
          log_error 'error', "Error comparing #{label}", 'path', user_path, true do
            log_status_bottom 'tip', 'Make sure you supply a file name', :white
          end
        end
      end

      def url_to_string(url)
        begin
          file_contents = open(url).read
        rescue *[OpenURI::HTTPError, SocketError] => ex
          log_error 'error', "Error browsing #{url}",
                    'message', ex
          exit 1
        end

        file_contents
      end

      def log_unmatched(compare, against, label, color)
        count = 0

        compare.each do |item|
          unless against.include?(item)
            log_status_bottom label, item, color
            count += 1
          end
        end

        count
      end

      def create_rsa_certificate(secrets_path, keyout, out)
        "openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 -subj '/C=US/ST=Foo/L=Bar/O=Baz/CN=qux.com' -keyout #{secrets_path}/#{keyout} -out #{secrets_path}/#{out}"
      end

      def galaxy_file_path
        "#{File.expand_path File.dirname(__FILE__)}/templates/includes/Galaxyfile"
      end

      def inventory_file_path
        "#{File.expand_path File.dirname(__FILE__)}/templates/includes/inventory/group_vars/all.yml"
      end

      def playbook_file_path
        "#{File.expand_path File.dirname(__FILE__)}/templates/play.rb"
      end

      def install_role_dependencies
        log_thor_task 'shell', 'Updating ansible roles from the galaxy'

        galaxy_install = "ansible-galaxy install -r #{galaxy_file_path} --force"
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

        log_thor_task 'shell', "Creating #{file}"
        run "cp #{base_path}/#{file} #{destination_root_path}/#{file}"
      end

      def nuke_redis(namespace)
        log_thor_task 'root', 'Removing redis keys'
        run "redis-cli KEYS '#{namespace}:*' | xargs --delim='\n' redis-cli DEL"
      end

      def nuke_directory
        log_thor_task 'root', 'Deleting directory'
        run "rm -rf #{@active_path}"
      end

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