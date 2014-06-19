require 'yaml'
require_relative '../test_helper'

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

  def test_new_app
    assert_new_app extras: :assert
  end

  def test_new_app_with_auth
    assert_new_app '--auth', extras: :assert
  end

  def test_new_app_without_extras
    assert_new_app '--skip-extras', extras: :refute
  end

  def test_play
    assert_play
  end

  def test_diff
    assert_play

    @target_path = ''
    assert_orats 'diff', 'Compare this version of'
  end

  def test_version
    assert_orats 'version', 'Orats'
  end

  private

  def assert_orats(command, match_regex, extras: nil)
    out, err = capture_orats(command)

    assert_match /#{match_regex}/, out

    assert_or_refute_extras extras if extras
  end

  def assert_new_app(flags = '', extras: nil)
    @target_path         = generate_app_name
    absolute_target_path = "#{TEST_PATH}/#{@target_path}"
    @extra_flags         = "#{ORATS_NEW_FLAGS} #{flags}"

    assert_orats 'new', 'Start your server', extras: extras

    if extras == :assert
      assert_ansible_yaml "#{absolute_target_path}/inventory/group_vars/all.yml"
      absolute_target_path << "/services/#{@target_path}"
    end

    assert_app_tests_pass absolute_target_path
  end

  def assert_app_tests_pass(target_path)
    out, err = capture_subprocess_io do
      system "cd #{target_path} && bundle exec rake test"
    end

    log_rails_test_results out
    assert out.include?('0 failures') && out.include?('0 errors'), err
  end

  def assert_play
    @target_path = generate_app_name
    assert_orats 'play', 'success'
    assert_ansible_yaml "#{TEST_PATH}/#{@target_path}/site.yml"
  end

  def assert_nuked(options = {})
    out, err = capture_subprocess_io do
      orats "nuke #{@target_path}", flags: options[:flags], answer: 'y'
    end

    assert_match /#{@target_path}/, out
    system "rm -rf #{TEST_PATH}"
  end

  def assert_in_file(file_path, match_regex)
    file_contents = `cat #{file_path}`
    assert_match /#{match_regex}/, file_contents
  end

  def assert_path(file_or_dir)
    assert File.exists?(file_or_dir), "Expected path '#{file_or_dir}' to exist"
  end

  def refute_path(file_or_dir)
    refute File.exists?(file_or_dir), "Expected path '#{file_or_dir}' to exist"
  end

  def assert_or_refute_extras(assert_or_refute)
    absolute_target_path = "#{TEST_PATH}/#{@target_path}"

    assert_path absolute_target_path
    send("#{assert_or_refute.to_s}_path",
         "#{absolute_target_path}/inventory")
    send("#{assert_or_refute.to_s}_path",
         "#{absolute_target_path}/secrets")
  end

  def assert_ansible_yaml(file_path)
    begin
      file                 = IO.read(file_path)
      invalid_ansible_yaml = file.match(/^([^#].\w): {/)

      if invalid_ansible_yaml
        assert false, "Invalid yaml syntax found near:\n #{invalid_ansible_yaml}\n\nYou need to include quotes around values that start with jinja template tags:\n Example, foo: '{{ bar }}'"
        return
      end

      assert YAML.load(file)
    rescue Psych::SyntaxError => ex
      assert false, ex.message
    end
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

    puts
    puts '-'*80
    puts 'Results of running `bundle exec rake test` on the generated test app:'
    puts '-'*80
    puts out_lines.join("\n\n").rstrip
    puts '-'*80
    puts
  end
end
