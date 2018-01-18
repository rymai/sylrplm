# frozen_string_literal: true

require 'test_helper'

class RolesControllerTest < ActionController::TestCase
  test 'should get index' do
    login_as_admin(@request)
    get :index
    assert_response :success
    assert_not_nil assigns(:roles)
  end

  test 'should get new' do
    login_as_admin(@request)
    get :new
    assert_response :success
  end

  test 'should create role' do
    login_as_admin(@request)
    assert_difference('Role.count') do
      post :create, role: { title: 'title' }
    end
    assert_response :success
    # assert_redirected_to role_path(assigns(:role))
  end

  test 'should show role' do
    login_as_admin(@request)
    get :show, id: roles(:Role_1).to_param
    assert_response :success
  end

  test 'should get edit' do
    login_as_admin(@request)
    get :edit, id: roles(:Role_1).to_param
    assert_response :success
  end

  test 'should update role' do
    login_as_admin(@request)
    put :update, id: roles(:Role_1).to_param, role: {}
    assert_response :success
  end

  test 'should destroy role' do
    login_as_admin(@request)
    assert_difference('Role.count', -1) do
      delete :destroy, id: roles(:Role_1).to_param
    end

    assert_redirected_to roles_path
  end
end
