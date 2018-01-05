# frozen_string_literal: true

require File.dirname(__FILE__) + '/../test_helper'

class CustomersControllerTest < ActionController::TestCase
  test 'should get index' do
    login_as_admin(@request)
    get :index
    assert_response :success
    assert_not_nil assigns(:customers)
  end

  test 'should get new' do
    login_as_admin(@request)
    get :new
    assert_response :success
  end

  test 'should create customer' do
    login_as_admin(@request)
    assert_difference('Customer.count') do
      post :create, customer: { owner_id: 1, ident: 'CUSTO01', designation: 'test Custo', date: '2015-10-10' }
    end
    assert_response :success
    # assert_redirected_to customer_path(assigns(:customer))
  end

  test 'should show customer' do
    login_as_admin(@request)
    get :show, id: customers(:Customer_1).to_param
    assert_response :success
  end

  test 'should get edit' do
    login_as_admin(@request)
    get :edit, id: customers(:Customer_1).to_param
    assert_response :success
  end

  test 'should update customer' do
    login_as_admin(@request)
    put :update, id: customers(:Customer_1).to_param, customer: {}
    assert_response :success
    # assert_redirected_to customer_path(assigns(:customer))
  end

  test 'should destroy customer' do
    login_as_admin(@request)
    assert_difference('Customer.count', -1) do
      delete :destroy, id: customers(:Customer_1).to_param
    end
    assert_redirected_to customers_path
  end
end
