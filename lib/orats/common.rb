require 'orats/postgres'
require 'orats/process'
require 'orats/redis'
require 'orats/shell'
require 'orats/ui'

module Orats
  # common class that other CLI driven classes subclass
  class Common
    include Thor::Base
    include Thor::Shell
    include Thor::Actions
    include Shell
    include UI
    include Process
    include Postgres
    include Redis

    def initialize(target_path = '', options = {})
      @target_path = target_path
      @options     = options

      self.destination_root = Dir.pwd
      @behavior             = :invoke
    end

    def base_path
      File.join(File.expand_path(File.dirname(__FILE__)))
    end

    def url_to_string(url)
      open(url).read
      rescue *[OpenURI::HTTPError, SocketError] => ex
        error 'Unable to access URL', ex
        exit 1
    end

    def file_to_string(path)
      if File.exist?(path) && File.file?(path)
        IO.read path
      else
        error 'Path not found', path
        exit 1
      end
    end

    def exit_if_path_exists(extend_path = '')
      task 'Check if path exists'

      extended_path = @target_path.dup

      unless extend_path.empty?
        extended_path = File.join(extended_path, extend_path)
      end

      return unless Dir.exist?(extended_path) || File.exist?(extended_path)

      error 'Path already exists', extended_path
      exit 1
    end

    def exit_if_invalid_system
      exit_if_process :not_found, 'rails', 'git', 'psql', 'redis-cli'
      exit_if_process :not_running, 'postgres', 'redis'

      exit_if_postgres_unreachable
      exit_if_redis_unreachable
    end

    def run_rake(command)
      task 'Run rake command'

      run_from @target_path, "bundle exec rake #{command}"
    end
  end
end
