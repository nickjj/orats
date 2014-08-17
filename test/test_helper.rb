require 'minitest/autorun'
require 'securerandom'
require_relative '../lib/orats/commands/new/server'

module Orats
  # test helpers
  module Test
    include Commands::New::Server

    # creating and destroying databases needs to be done with raw psql
    # commands when the host isn't localhost or 127.0.0.1

    TEST_PATH         = ENV['TEST_PATH']         || '/tmp/orats'
    POSTGRES_LOCATION = ENV['POSTGRES_LOCATION'] || 'localhost'
    POSTGRES_PORT     = ENV['POSTGRES_PORT']     || '5432'
    POSTGRES_USERNAME = ENV['POSTGRES_USERNAME'] || 'postgres'
    POSTGRES_PASSWORD = ENV['POSTGRES_PASSWORD'] || ''
    REDIS_LOCATION    = ENV['REDIS_LOCATION']    || 'localhost'
    REDIS_PORT        = ENV['REDIS_PORT']        || '6379'
    REDIS_PASSWORD    = ENV['REDIS_PASSWORD']    || ''

    CREDENTIALS = "-l #{POSTGRES_LOCATION} -o #{POSTGRES_PORT} " + \
                  "-u #{POSTGRES_USERNAME} -p #{POSTGRES_PASSWORD} " + \
                  "-n #{REDIS_LOCATION} -r #{REDIS_PORT} -d #{REDIS_PASSWORD}"

    INCLUDES_PATH   = File.absolute_path('../../lib/orats/templates/includes',
                                         __FILE__)
    BINARY_PATH     = File.absolute_path('../../bin/orats', __FILE__)
    ORATS_NEW_FLAGS = "#{CREDENTIALS} -S"

    def orats(command, options = {})
      cmd, app_name   = command.split(' ')
      command         = "#{cmd} #{TEST_PATH}/#{app_name}" unless app_name.nil?

      insert_answer = answer(options)
      if insert_answer
        prepend_command = "#{insert_answer} | "
      else
        prepend_command = ''
      end

      system "#{prepend_command} #{BINARY_PATH} #{command} #{options[:flags]}"
    end

    def assert_count(input, regex, expected)
      assert input.scan(regex).size == expected,
             "Found #{input.scan(regex).size} matches for '#{regex}' but " + \
             "expected #{expected}"
    end

    def assert_in_file(file_path, match_regex)
      file_contents = `cat #{file_path}`
      assert_match(/#{match_regex}/, file_contents)
    end

    def assert_path(file_or_dir)
      assert File.exist?(file_or_dir),
             "Expected path '#{file_or_dir}' to exist"
    end

    def refute_path(file_or_dir)
      refute File.exist?(file_or_dir),
             "Expected path '#{file_or_dir}' to exist"
    end

    private

    def answer(options)
      return unless options.key?(:answer)

      if options[:answer] == 'y' || options[:answer] == 'yes'
        'yes'
      else
        'no'
      end
    end

    def generate_app_name
      "a_#{SecureRandom.hex(8)}"
    end
  end
end
