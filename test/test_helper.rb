require 'minitest/autorun'
require 'securerandom'
require_relative '../lib/orats/commands/new/server'

module Orats
  module Test
    include Commands::New::Server

    BINARY_PATH = File.absolute_path('../../bin/orats', __FILE__)
    TEST_PATH   = '/tmp/orats/test'
    ORATS_FLAGS = '--pg-password pleasedonthackme --skip-server-start'

    def orats(command, options = {})
      cmd, app_name   = command.split(' ')
      prepend_command = ''

      command         = "#{cmd} #{TEST_PATH}/#{app_name}" if command.include?(' ')

      if options.has_key?(:answer)
        options[:answer] == 'y' || options[:answer] == 'yes' ? insert_answer = 'yes' : insert_answer = 'echo'

        prepend_command = "#{insert_answer} | "
      end

      system "#{prepend_command} #{BINARY_PATH} #{command} #{options[:flags]}"
    end

    private

    def generate_app_name
      "a_#{SecureRandom.hex(8)}"
    end
  end
end
