require 'test_helper'

class ForumItemsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:forum_items)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create forum_item" do
    assert_difference('ForumItem.count') do
      post :create, :forum_item => { }
    end

    assert_redirected_to forum_item_path(assigns(:forum_item))
  end

  test "should show forum_item" do
    get :show, :id => forum_items(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => forum_items(:one).to_param
    assert_response :success
  end

  test "should update forum_item" do
    put :update, :id => forum_items(:one).to_param, :forum_item => { }
    assert_redirected_to forum_item_path(assigns(:forum_item))
  end

  test "should destroy forum_item" do
    assert_difference('ForumItem.count', -1) do
      delete :destroy, :id => forum_items(:one).to_param
    end

    assert_redirected_to forum_items_path
  end
end
