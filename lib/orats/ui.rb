# frozen_string_literal: true

module Orats
  # print out various messages to the terminal
  module UI
    include Thor::Shell

    def task(message, color = :blue)
      puts
      log 'task', message, color, true
    end

    def results(results, tag, message)
      puts
      log 'results', results, :magenta, true
      log tag, message, :white
    end

    def error(error, message)
      puts
      log 'error', error, :red, :bold
      log 'from', message, :yellow
    end

    def log(tag, message, ansi_color, bold = false)
      msg = if bold
              set_color(message, :bold)
            else
              set_color(message)
            end

      say_status tag, msg, ansi_color
    end
  end
end
