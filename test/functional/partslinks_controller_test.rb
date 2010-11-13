require 'test_helper'

class PartslinksControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:partslinks)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create partslink" do
    assert_difference('Partslink.count') do
      post :create, :partslink => { }
    end

    assert_redirected_to partslink_path(assigns(:partslink))
  end

  test "should show partslink" do
    get :show, :id => partslinks(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => partslinks(:one).to_param
    assert_response :success
  end

  test "should update partslink" do
    put :update, :id => partslinks(:one).to_param, :partslink => { }
    assert_redirected_to partslink_path(assigns(:partslink))
  end

  test "should destroy partslink" do
    assert_difference('Partslink.count', -1) do
      delete :destroy, :id => partslinks(:one).to_param
    end

    assert_redirected_to partslinks_path
  end
end
