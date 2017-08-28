require 'test_helper'

class PagesControllerTest < ActionDispatch::IntegrationTest
  test 'expect home page' do
    get root_url

    assert_response :success
  end
end
