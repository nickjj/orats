require 'socket'
require 'timeout'

module Orats
  module Foreman
    def foreman_init
      log_foreman_start
      attempt_to_start unless @options[:skip_foreman_start]
    end

    private

    def attempt_to_start
      while port_taken? do
        log_status_top 'error', "Another application is using port 3000\n", :red

        exit 1 if no?('Would you like to try running the server again? (y/N)', :cyan)
      end

      puts

      run_from @active_path, 'bundle exec foreman start'
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