require 'test_helper'

class StatusobjectsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:statusobjects)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create statusobject" do
    assert_difference('Statusobject.count') do
      post :create, :statusobject => { }
    end

    assert_redirected_to statusobject_path(assigns(:statusobject))
  end

  test "should show statusobject" do
    get :show, :id => statusobjects(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => statusobjects(:one).to_param
    assert_response :success
  end

  test "should update statusobject" do
    put :update, :id => statusobjects(:one).to_param, :statusobject => { }
    assert_redirected_to statusobject_path(assigns(:statusobject))
  end

  test "should destroy statusobject" do
    assert_difference('Statusobject.count', -1) do
      delete :destroy, :id => statusobjects(:one).to_param
    end

    assert_redirected_to statusobjects_path
  end
end
