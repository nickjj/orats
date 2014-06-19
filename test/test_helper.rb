require 'minitest/autorun'
require 'securerandom'
require_relative '../lib/orats/commands/new/server'

module Orats
  module Test
    include Commands::New::Server

    TEST_PATH = ENV['TEST_PATH'] || '/tmp/orats'
    POSTGRES_LOCATION =  ENV['POSTGRES_LOCATION'] || 'localhost'
    POSTGRES_USERNAME = ENV['POSTGRES_USERNAME'] || 'postgres'
    POSTGRES_PASSWORD = ENV['POSTGRES_PASSWORD'] || 'pleasedonthackme'
    REDIS_LOCATION = ENV['REDIS_LOCATION'] || 'localhost'
    REDIS_PASSWORD = ENV['REDIS_PASSWORD'] || ''

    CREDENTIALS = "-l #{POSTGRES_LOCATION} -u #{POSTGRES_USERNAME} -p #{POSTGRES_PASSWORD} -n #{REDIS_LOCATION} -d #{REDIS_PASSWORD}"

    BINARY_PATH     = File.absolute_path('../../bin/orats', __FILE__)
    ORATS_NEW_FLAGS = "#{CREDENTIALS} -FG"

    def orats(command, options = {})
      cmd, app_name   = command.split(' ')
      prepend_command = ''
      command         = "#{cmd} #{TEST_PATH}/#{app_name}" unless app_name.nil?

      if options.has_key?(:answer)
        options[:answer] == 'y' || options[:answer] == 'yes' ?
            insert_answer = 'yes' : insert_answer = 'echo'

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
