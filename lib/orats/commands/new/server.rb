require 'socket'
require 'timeout'

module Orats
  module Commands
    module New
      # handle starting the server
      module Server
        START_COMMAND = 'bundle exec foreman start'

        def server_start
          if @options[:skip_server_start]
            message = 'Start your'
          else
            message = 'Starting'
          end

          display_notice message
          attempt_to_start unless @options[:skip_server_start]
        end

        private

        def display_notice(message)
          results "#{message} server with the following commands",
                  'command', "cd #{@target_path}"
          log 'command', START_COMMAND, :white
        end

        def attempt_to_start
          while port_taken?
            error 'Failed to start server',
                  "Another application is using port 3000\n"
            puts
            exit 1 if no?('Would you like to try running ' + \
                          ' the server again? (y/N)', :cyan)
          end

          puts
          run_from @target_path, START_COMMAND
        end

        def port_taken?
          begin
            start_server?
          rescue Timeout::Error
            false
          end

          false
        end

        def start_server?
          Timeout.timeout(5) do
            s = TCPSocket.new('localhost', 3000)
            s.close

            true
          end

          rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
            false
        end
      end
    end
  end
end
