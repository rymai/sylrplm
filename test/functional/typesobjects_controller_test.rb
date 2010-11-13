require 'test_helper'

class TypesobjectsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:typesobjects)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create typesobject" do
    assert_difference('Typesobject.count') do
      post :create, :typesobject => { }
    end

    assert_redirected_to typesobject_path(assigns(:typesobject))
  end

  test "should show typesobject" do
    get :show, :id => typesobjects(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => typesobjects(:one).to_param
    assert_response :success
  end

  test "should update typesobject" do
    put :update, :id => typesobjects(:one).to_param, :typesobject => { }
    assert_redirected_to typesobject_path(assigns(:typesobject))
  end

  test "should destroy typesobject" do
    assert_difference('Typesobject.count', -1) do
      delete :destroy, :id => typesobjects(:one).to_param
    end

    assert_redirected_to typesobjects_path
  end
end
