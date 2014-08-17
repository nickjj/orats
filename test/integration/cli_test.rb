require_relative '../test_helper'

# integration tests for the orats cli
class TestCLI < Minitest::Test
  include Orats::Test

  attr_accessor :target_path, :extra_flags

  def startup
    @target_path = ''
    @extra_flags = ''
  end

  def teardown
    assert_nuked unless @target_path.nil?
  end

  def test_new
    assert_new
  end

  def test_new_with_auth
    assert_new '--template auth'
  end

  def test_new_with_puma
    assert_new '--backend puma'
  end

  def test_new_with_invalid_template
    @target_path = generate_app_name
    @extra_flags = "#{ORATS_NEW_FLAGS} --template foo"

    assert_orats 'new', 'not a valid template'
  end

  def test_templates
    assert_orats 'templates', 'auth'
  end

  def test_new_with_custom
    custom_file = "#{TEST_PATH}/custom_file.rb"
    `mkdir -p #{TEST_PATH}`
    File.open(custom_file, 'w') do |file|
      file.write "file 'custom_file.rb', 'class CustomFile\nend'"
    end

    assert_new "--custom #{custom_file}"
    assert_path "#{TEST_PATH}/#{@target_path}/custom_file.rb"
  end

  def test_version
    assert_orats 'version', 'Orats'
  end

  private

  def assert_orats(command, match_regex)
    out, err = capture_orats(command)

    assert_match(/#{match_regex}/, out, err) unless match_regex.empty?
  end

  def assert_new(flags = '')
    @target_path         = generate_app_name
    @extra_flags         = "#{ORATS_NEW_FLAGS} #{flags}"
    absolute_target_path = "#{TEST_PATH}/#{@target_path}"

    assert_orats 'new', 'Start your server'
    assert_new_tests_pass absolute_target_path
  end

  def assert_new_tests_pass(target_path)
    out, err = capture_subprocess_io do
      system "cd #{target_path} && bundle exec rake test"
    end

    log_rails_test_results out
    assert out.include?('0 failures') && out.include?('0 errors'), err
  end

  def assert_nuked(options = {})
    out, _ = capture_subprocess_io do
      orats "nuke #{@target_path}", flags: options[:flags], answer: 'y'
    end

    assert_match(/#{@target_path}/, out)
    system "rm -rf #{TEST_PATH}"
  end

  def capture_orats(command)
    out, err = capture_subprocess_io do
      orats "#{command} #{@target_path}", flags: @extra_flags
    end

    [out, err]
  end

  def log_rails_test_results(out)
    out_lines = out.split("\n")

    out_lines.delete_if do |line|
      line.include?('Sidekiq') || line.start_with?('.') ||
          line.include?('Running') || line.include?('Run options') ||
          line.empty?
    end
  end

  def print_rails_test_results(out)
    puts
    puts '-' * 80
    puts 'Results of running `bundle exec rake test` on the generated test app:'
    puts '-' * 80
    puts out.join("\n\n").rstrip
    puts '-' * 80
    puts
  end
end
