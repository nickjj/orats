require 'test_helper'

class AccountTest < ActiveSupport::TestCase
  def setup
    @account = accounts(:foo)
  end

  def teardown
    @account = nil
  end

  test 'expect new account' do
    assert @account.valid?
    assert_not_nil @account.email
    assert_not_nil @account.encrypted_password
  end

  test 'expect guest to be default role' do
    no_role = accounts(:no_role)
    assert_equal 'guest', no_role.role
  end

  test 'expect invalid role to not save' do
    bad_role = accounts(:bad_role)
    assert_not bad_role.valid?
  end

  test 'expect e-mail to be unique' do
    duplicate = Account.create(email: 'foo@bar.com')

    assert_not duplicate.valid?
  end

  test 'expect random password if password is empty' do
    @account.password = ''
    @account.encrypted_password = ''
    @account.save

    random_password = Account.generate_password
    assert_equal 10, random_password.length
  end

  test 'expect random password of 20 characters' do
    assert_equal 20, Account.generate_password(20).length
  end
end