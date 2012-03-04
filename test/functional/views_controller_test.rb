require 'test_helper'

class ViewsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:views)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create view" do
    assert_difference('View.count') do
      post :create, :view => { }
    end

    assert_redirected_to view_path(assigns(:view))
  end

  test "should show view" do
    get :show, :id => views(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => views(:one).to_param
    assert_response :success
  end

  test "should update view" do
    put :update, :id => views(:one).to_param, :view => { }
    assert_redirected_to view_path(assigns(:view))
  end

  test "should destroy view" do
    assert_difference('View.count', -1) do
      delete :destroy, :id => views(:one).to_param
    end

    assert_redirected_to views_path
  end
end
