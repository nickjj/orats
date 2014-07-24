module Orats
  # manage the postgres process
  module Postgres
    def postgres_bin(bin_name = 'psql')
      exec = "#{bin_name} -h #{@options[:pg_location]} -U " + \
                      "#{@options[:pg_username]}"

      return exec if @options[:pg_password].empty?
      exec.prepend("PGPASSWORD=#{@options[:pg_password]} ")
    end

    def create_database
      if local_postgres?
        run_rake 'db:create:all'
      else
        manually_create_postgres_db
      end
    end

    def drop_database(name)
      if local_postgres?
        run_rake 'db:drop:all'
      else
        manually_delete_postgres_db File.basename(name)
      end
    end

    def exit_if_postgres_unreachable
      task 'Check if you can connect to postgres'

      return if run("#{postgres_bin} -c 'select 1'")

      error 'Cannot connect to postgres', 'attempt to SELECT 1'
      exit 1
    end

    def exit_if_database_exists
      task 'Check if the postgres database exists'

      # detect if the database already exists
      database = File.basename(@target_path)
      return if run("#{postgres_bin} -d #{database} -l | " + \
                    "grep #{database} | wc -l", capture: true).chomp == '0'

      error "'#{database}' database already exists",
            'attempt to check database existence'
      puts

      exit 1 unless yes?('Would you like to continue anyways? (y/N)',
                         :cyan)
    end

    private

    def local_postgres?
      @options[:pg_location] == 'localhost' ||
      @options[:pg_location] == '127.0.0.1'
    end

    def manually_create_postgres_db
      database = File.basename(@target_path)
      test_database = "#{database}_test"

      createdb(database)
      createdb(test_database)
    end

    def createdb(database)
      return if run("#{postgres_bin('createdb')} #{database}")

      log 'Skipped creating postgres database',
          "#{database} already exists", :yellow
    end

    def manually_delete_postgres_db(name)
      database = File.basename(name)
      test_database = "#{database}_test"

      dropdb(database)
      dropdb(test_database)
    end

    def dropdb(database)
      return if run("#{postgres_bin('dropdb')} #{database}")

      log 'Skipped dropping postgres database',
          "#{database} does not exists", :yellow
    end
  end
end
