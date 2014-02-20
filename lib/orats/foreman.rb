require 'socket'
require 'timeout'

module Orats
  module Foreman
    def foreman_init

      @options[:skip_foreman_start] ? message = 'Start your' : message = 'Starting'

      puts  '', '='*80
      say_status  'action', "\e[1m#{message} server with the following commands:\e[0m", :cyan
      say_status  'command', "cd #{@active_path}", :magenta
      say_status  'command', 'bundle exec foreman start', :magenta
      puts  '='*80, ''

      attempt_to_start unless @options[:skip_foreman_start]
    end

    private

      def attempt_to_start
        while port_taken? do
          puts
          say_status  'error', "\e[1mAnother application is using port 3000\n\e[0m", :red
          puts        '-'*80

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