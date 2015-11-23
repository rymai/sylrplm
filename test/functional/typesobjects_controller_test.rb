require 'test_helper'

class TypesobjectsControllerTest < ActionController::TestCase
  test "should get index" do
   login_as_admin(@request)
    get :index
    assert_response :success
    assert_not_nil assigns(:typesobjects)
  end

  test "should get new" do
    login_as_admin(@request)
    get :new
    assert_response :success
  end

  test "should create typesobject" do
    login_as_admin(@request)
    assert_difference('Typesobject.count') do
      post :create, :typesobject => {:forobject=>"part", :name=>"theType" }
    end
    assert_response :success
    #assert_redirected_to typesobject_path(assigns(:typesobject))
  end

  test "should show typesobject" do
    login_as_admin(@request)
    get :show, :id => typesobjects(:Typesobject_89393353).to_param
    assert_response :success
  end

  test "should get edit" do
   login_as_admin(@request)
    get :edit, :id => typesobjects(:Typesobject_89393353).to_param
    assert_response :success
  end

  test "should update typesobject" do
    login_as_admin(@request)
    put :update, :id => typesobjects(:Typesobject_89393353).to_param, :typesobject => { }
   assert_response :success
  end

  test "should destroy typesobject" do
    login_as_admin(@request)
    assert_difference('Typesobject.count', -1) do
      delete :destroy, :id => typesobjects(:Typesobject_89393353).to_param
    end
    assert_redirected_to typesobjects_path
  end
end
