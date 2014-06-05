module Orats
  module AfterRails
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
  end
end