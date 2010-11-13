require 'test_helper'

class ChecksControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:checks)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create check" do
    assert_difference('Check.count') do
      post :create, :check => { }
    end

    assert_redirected_to check_path(assigns(:check))
  end

  test "should show check" do
    get :show, :id => checks(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => checks(:one).to_param
    assert_response :success
  end

  test "should update check" do
    put :update, :id => checks(:one).to_param, :check => { }
    assert_redirected_to check_path(assigns(:check))
  end

  test "should destroy check" do
    assert_difference('Check.count', -1) do
      delete :destroy, :id => checks(:one).to_param
    end

    assert_redirected_to checks_path
  end
end
