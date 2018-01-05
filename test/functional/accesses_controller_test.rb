# frozen_string_literal: true

require 'test_helper'

class AccessesControllerTest < ActionController::TestCase
  test 'should get index' do
    login_as_admin(@request)
    get :index
    assert_response :success
    assert_not_nil assigns(:accesses)
  end

  test 'should get new' do
    login_as_admin(@request)
    get :new
    assert_response :success
  end

  test 'should create access' do
    login_as_admin(@request)
    assert_difference('Access.count') do
      post :create, access: { controller: 'PartsController_', action: 'show_', roles: '(admin | creator | designer | valider | analyst | project_manager | plm_actor) & (!consultant)' }
    end
    assert_response :success
    # assert_redirected_to access_path(assigns(:access))
  end

  test 'should show access' do
    login_as_admin(@request)
    get :show, id: accesses(:one).to_param
    assert_response :success
  end

  test 'should get edit' do
    login_as_admin(@request)
    get :edit, id: accesses(:one).to_param
    assert_response :success
  end

  test 'should update access' do
    login_as_admin(@request)
    put :update, id: accesses(:one).to_param, access: {}
    assert_response :success
    # assert_redirected_to access_path(assigns(:access))
  end

  test 'should destroy access' do
    login_as_admin(@request)
    assert_difference('Access.count', -1) do
      delete :destroy, id: accesses(:one).to_param
    end
    assert_redirected_to accesses_path
  end
end
