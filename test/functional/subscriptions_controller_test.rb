require 'test_helper'

class SubscriptionsControllerTest < ActionController::TestCase
  test "should get index" do
     login_as_admin(@request)
     get :index
    assert_response :success
    assert_not_nil assigns(:subscriptions)
  end

  test "should get new" do
     login_as_admin(@request)
     get :new
    assert_response :success
  end

  test "should create subscription" do
     login_as_admin(@request)
     assert_difference('Subscription.count') do
      post :create, :subscription => { :name=>"sub01", :designation=>"designation",:owner_id=>1}
    end
   assert_response :success
   # assert_redirected_to subscription_path(assigns(:subscription))
  end

  test "should show subscription" do
     login_as_admin(@request)
     get :show, :id => subscriptions(:Subscription_1).to_param
    assert_response :success
  end

  test "should get edit" do
     login_as_admin(@request)
     get :edit, :id => subscriptions(:Subscription_1).to_param
    assert_response :success
  end

  test "should update subscription" do
     login_as_admin(@request)
     put :update, :id => subscriptions(:Subscription_1).to_param, :subscription => { }
    assert_response :success
    #assert_redirected_to subscription_path(assigns(:subscription))
  end

  test "should destroy subscription" do
     login_as_admin(@request)
     assert_difference('Subscription.count', -1) do
      delete :destroy, :id => subscriptions(:Subscription_1).to_param
    end
    assert_redirected_to subscriptions_path
  end
end
