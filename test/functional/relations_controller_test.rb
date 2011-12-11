require 'test_helper'

class RelationsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:relations)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create relation" do
    assert_difference('Relation.count') do
      post :create, :relation => { }
    end

    assert_redirected_to relation_path(assigns(:relation))
  end

  test "should show relation" do
    get :show, :id => relations(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => relations(:one).to_param
    assert_response :success
  end

  test "should update relation" do
    put :update, :id => relations(:one).to_param, :relation => { }
    assert_redirected_to relation_path(assigns(:relation))
  end

  test "should destroy relation" do
    assert_difference('Relation.count', -1) do
      delete :destroy, :id => relations(:one).to_param
    end

    assert_redirected_to relations_path
  end
end
