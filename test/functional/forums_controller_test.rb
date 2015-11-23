require 'test_helper'

class ForumsControllerTest < ActionController::TestCase
  test "should get index" do
    login_as_admin(@request)
    get :index
    assert_response :success
    assert_not_nil assigns(:forums)
  end

  test "should get new" do
    login_as_admin(@request)
    get :new
    assert_response :success
  end

  test "should create forum" do
    login_as_admin(@request)
    assert_difference('Forum.count') do
      post :create, :forum => { :typesobject_id=>989626522, :statusobject_id=>14, :subject=>"MyString", :description=>"MyText", :owner_id=> 1}
    end
 assert_response :success
   # assert_redirected_to forum_path(assigns(:forum))
  end

  test "should show forum" do
    login_as_admin(@request)
    get :show, :id => forums(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    login_as_admin(@request)
    get :edit, :id => forums(:one).to_param
    assert_response :success
  end

  test "should update forum" do
    login_as_admin(@request)
    put :update, :id => forums(:one).to_param, :forum => { }
     assert_response :success
     #assert_redirected_to forum_path(assigns(:forum))
  end

  test "should destroy forum" do
    login_as_admin(@request)
    assert_difference('Forum.count', -1) do
      delete :destroy, :id => forums(:one).to_param
    end
    assert_redirected_to forums_path
  end
end
