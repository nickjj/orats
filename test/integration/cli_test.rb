require_relative '../test_helper'

class TestCLI < Minitest::Test
  include Orats::Test

  def test_new_app
    app_name = generate_app_name

    out, err = capture_subprocess_io do
      orats "new #{app_name}", flags: ORATS_FLAGS
    end

    assert_match /Start your server/, out

    assert_path_exists "#{TEST_PATH}/#{app_name}/inventory"
    assert_path_exists "#{TEST_PATH}/#{app_name}/secrets"

    assert_nuked app_name
  end

  def test_new_app_with_auth
    app_name = generate_app_name
    gemfile_path = "#{TEST_PATH}/#{app_name}/services/#{app_name}/Gemfile"

    out, err = capture_subprocess_io do
      orats "new #{app_name}", flags: "--auth #{ORATS_FLAGS}"
    end

    assert_match /Start your server/, out

    assert_path_exists "#{TEST_PATH}/#{app_name}/inventory"
    assert_path_exists "#{TEST_PATH}/#{app_name}/secrets"
    assert_path_exists "#{TEST_PATH}/#{app_name}/services/#{app_name}"

    assert_in_file gemfile_path, /devise/
    assert_in_file gemfile_path, /devise-async/
    assert_in_file gemfile_path, /pundit/

    assert_nuked app_name
  end

  def test_new_app_without_extras
    app_name = generate_app_name

    out, err = capture_subprocess_io do
      orats "new #{app_name}", flags: "--skip-extras #{ORATS_FLAGS}"
    end

    refute_path_exists "#{TEST_PATH}/#{app_name}/inventory"
    refute_path_exists "#{TEST_PATH}/#{app_name}/secrets"
    refute_path_exists "#{TEST_PATH}/#{app_name}/services/#{app_name}"
    assert_path_exists "#{TEST_PATH}/#{app_name}"

    assert_nuked app_name
  end

  def test_play
    app_name = generate_app_name

    out, err = capture_subprocess_io do
      orats "play #{app_name}"
    end

    assert_match /success/, out
    assert_nuked app_name
  end

  def test_outdated
    app_name = generate_app_name

    out, err = capture_subprocess_io do
      orats "play #{app_name}"
    end
    assert_match /success/, out

    out, err = capture_subprocess_io do
      orats 'outdated'
    end
    assert_match /Comparing this version of/, out

    assert_nuked app_name
  end

  def test_version
    out, err = capture_subprocess_io do
      orats 'version'
    end

    assert_match /Orats/, out
  end

  private

  def assert_nuked(app_name, options = {})
    out, err = capture_subprocess_io do
      orats "nuke #{app_name}", flags: options[:flags], answer: 'y'
    end

    assert_match /#{app_name}/, out
    system 'rm -rf /tmp/orats'
  end

  def assert_server_started
    assert port_taken?
  end

  def assert_path_exists(file_or_dir)
    assert File.exists?(file_or_dir), "Expected path '#{file_or_dir}' to exist"
  end

  def refute_path_exists(file_or_dir)
    refute File.exists?(file_or_dir), "Expected path '#{file_or_dir}' to exist"
  end

  def assert_in_file(file_path, regex)
    out, err = capture_subprocess_io do
      system "cat #{file_path}"
    end

    assert_match regex, out
  end

  def ensure_port_is_free
    skip 'Port 3000 is already in use, aborting test' if port_taken?
  end

  def kill_server(stdout_text)
    pid_lines = stdout_text.scan(/started with pid \d+/)

    puma = pid_lines[0].split(' ').last
    sidekiq = pid_lines[1].split(' ').last

    system "kill -9 #{puma} && kill -9 #{sidekiq}"
  end
end
