require File.dirname(__FILE__)+'/../test_helper'

class PartsControllerTest < ActionController::TestCase
  test "should get index" do
    login_as_admin(@request)
     get :index
    assert_response :success
    assert_not_nil assigns(:parts)
  end

  test "should get new" do
     login_as_admin(@request)
     get :new
    assert_response :success
  end

  test "should create part" do
     login_as_admin(@request)
     assert_difference('Part.count') do
      post :create, :part => { :owner=>users(:user_admin),:ident=>"part001", :designation=>"designation1",:date=>"2015/10/11"}
    end
assert_response :success
    #assert_redirected_to part_path(assigns(:part))
  end

  test "should show part" do
     login_as_admin(@request)
     get :show, :id => parts(:Part_1).to_param
    assert_response :success
  end

  test "should get edit" do
     login_as_admin(@request)
     get :edit, :id => parts(:Part_1).to_param
    assert_response :success
  end

  test "should update part" do
     login_as_admin(@request)
     put :update, :id => parts(:Part_1).to_param, :part => { }
    assert_redirected_to part_path(assigns(:part))
  end

  test "should destroy part" do
     login_as_admin(@request)
     post :create, :part => { :owner=>users(:user_admin),:ident=>"part002", :designation=>"designation2",:date=>"2015/10/11"}
     assert_difference('Part.count', -1) do
      delete :destroy, :id => Part.find_by_ident("part002").to_param
    end
    assert_redirected_to parts_path
  end
end
