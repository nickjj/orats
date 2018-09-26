# frozen_string_literal: true

require 'minitest/autorun'
require 'securerandom'

module Orats
  # test helpers
  module Test
    TEST_PATH      = ENV['TEST_PATH'] || '/tmp'
    TEMPLATES_PATH = File.absolute_path('../../lib/orats/templates', __FILE__)
    BINARY_PATH    = File.absolute_path('../../bin/orats', __FILE__)

    def orats(command, options = {})
      cmd, app_name = command.split(' ')
      command       = "#{cmd} #{TEST_PATH}/#{app_name}" unless app_name.nil?

      system "#{BINARY_PATH} #{command} #{options[:flags]}"
    end

    def assert_path(file_or_dir)
      assert File.exist?(file_or_dir),
             "Expected path '#{file_or_dir}' to exist"
    end

    private

    def absolute_test_path
      File.join(TEST_PATH, @target_path)
    end

    def generate_app_name
      "orats_#{SecureRandom.hex(8)}"
    end
  end
end
