require 'socket'
require 'timeout'

module Orats
  module Commands
    module Project
      module Server
        START_COMMAND = 'bundle exec foreman start'

        def server_start
          @options[:skip_server_start] ? message = 'Start your' : message = 'Starting'

          puts '', '='*80
          log_status_top 'action', "#{message} server with the following commands", :cyan
          log_status_bottom 'command', "cd #{@active_path}", :magenta, true
          log_status_bottom 'command', START_COMMAND, :magenta
          puts '='*80, ''

          attempt_to_start unless @options[:skip_server_start]
        end

        private

        def attempt_to_start
          while port_taken? do
            log_status_top 'error', "Another application is using port 3000\n", :red

            exit 1 if no?('Would you like to try running the server again? (y/N)', :cyan)
          end

          puts

          run_from @active_path, START_COMMAND
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
  end
end