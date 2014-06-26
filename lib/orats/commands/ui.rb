module Orats
  module Commands
    module UI
      include Thor::Shell

      def log_task(message)
        puts
        say_status 'task', "#{message}:", :yellow
        puts '-'*80, ''; sleep 0.25
      end

      def log_status_top(type, message, color)
        puts
        say_status type, set_color(message, :bold), color
      end

      def log_status_bottom(type, message, color, strip_newline = false)
        say_status type, message, color
        puts unless strip_newline
      end

      def log_results(results, message)
        log_status_top 'results', "#{results}:", :magenta
        log_status_bottom 'message', message, :white
      end

      def log_error(top_label, top_message, bottom_label, bottom_message, strip_newline = false)
        log_status_top top_label, "#{top_message}:", :red
        log_status_bottom bottom_label, bottom_message, :yellow, strip_newline
        yield if block_given?
      end

      def log_remote_info(top_label, top_message, bottom_label, bottom_message)
        log_status_top top_label, "#{top_message}:", :blue
        log_status_bottom bottom_label, bottom_message, :cyan
      end

      def run_from(path, command)
        run "cd #{path} && #{command} && cd -"
      end

      def git_commit(message)
        run_from @active_path, "git add -A && git commit -m '#{message}'"
      end
    end
  end
end