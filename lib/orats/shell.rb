module Orats
  module Shell
    def run_with_cd(command)
      run "cd #{@app_name} && #{command} && cd -"
    end

    def log_message(type, message)
      puts
      say_status  type, "#{message}...", :yellow
      puts        '-'*80, ''; sleep 0.25
    end

    def git_commit(message)
      run_with_cd "git add . && git commit -m '#{message}'"
    end

    def gsub_postgres_info(options)
      log_message 'root', 'Changing the postgres information'

      gsub_file "#{@app_name}/.env", ': localhost', ": #{options[:postgres_location]}"
      gsub_file "#{@app_name}/.env", ': postgres', ": #{options[:postgres_username]}"
      gsub_file "#{@app_name}/.env", ': supersecrets', ": #{options[:postgres_password]}"
    end

    def run_rake(command)
      log_message 'shell', 'Running rake commands'

      run_with_cd "bundle exec rake #{command}"
    end

    def bundle_install
      log_message 'shell', 'Running bundle install, this may take a while'

      run "cd #{@app_name} && bundle install && cd -"
    end

    def nuke_redis
      log_message 'root', 'Removing redis keys'

      run "redis-cli KEYS '#{@app_name_only}:*' | xargs --delim='\n' redis-cli DEL"
    end

    def nuke_directory
      log_message 'root', 'Deleting directory'

      run "rm -rf #{@app_name}"
    end
  end
end