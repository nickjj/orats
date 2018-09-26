# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../lib/orats/util'

# integration tests for the orats cli
class TestCLI < Minitest::Test
  include Orats::Test

  attr_accessor :target_path, :extra_flags

  def startup
    @target_path = ''
    @extra_flags = ''
  end

  def teardown
    FileUtils.rm_rf(absolute_test_path)
  end

  def test_new
    @target_path = generate_app_name

    assert_new

    Dir.glob("#{absolute_test_path}/**/*", File::FNM_DOTMATCH) do |file|
      next if file == '.' || file == '..' || File.directory?(file)

      text = File.read(file)

      %w(orats_base OratsBase VERSION).each do |term|
        refute_match term, text
      end
    end
  end

  def test_new_with_invalid_template
    @target_path = generate_app_name
    @extra_flags = '--template foo'

    assert_orats 'new', 'not a valid template'
  end

  def test_version
    @target_path = ''
    @extra_flags = ''

    assert_orats 'version', 'orats'
  end

  def test_underscore
    @target_path = ''
    @extra_flags = ''

    assert_equal 'foo', Util.underscore('foo')
    assert_equal 'foo_bar', Util.underscore('fooBar')
    assert_equal 'foo_bar_baz', Util.underscore('FooBarBaz')
  end

  def test_classify
    @target_path = ''
    @extra_flags = ''

    assert_equal 'Foo', Util.classify('foo')
    assert_equal 'FooBar', Util.classify('foo_bar')
    assert_equal 'FooBarBaz', Util.classify('foo_bar_baz')
  end

  private

  def assert_orats(command, match_regex)
    out, err = capture_orats(command)

    assert_match(/#{match_regex}/, out, err) unless match_regex.empty?
  end

  def capture_orats(command)
    out, err = capture_subprocess_io do
      cmd_arg = if @target_path
                  " #{@target_path}"
                else
                  ''
                end

      orats "#{command}#{cmd_arg}", flags: @extra_flags
    end

    [out, err]
  end

  def assert_new(flags = '')
    @target_path         = generate_app_name
    @extra_flags         = flags

    assert_orats 'new', 'Create'
    assert_path absolute_test_path
  end
end
