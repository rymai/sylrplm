# frozen_string_literal: true

require 'test_helper'

class ChecksControllerTest < ActionController::TestCase
  test 'should get index' do
    login_as_admin(@request)
    get :index
    assert_response :success
    assert_not_nil assigns(:checks)
  end

  test 'should get new' do
    login_as_admin(@request)
    get :new
    assert_response :success
  end

  test 'should create check' do
    login_as_admin(@request)
    assert_difference('Check.count') do
      post :create, check: { checkobject_plmtype: 'document', checkobject_id: '1', status: 'ok', out_user_id: 1, out_date: '2015/10/09', out_reason: 'reason', out_group_id: 1 }
    end
    assert_redirected_to check_path(assigns(:check))
  end

  test 'should show check' do
    login_as_admin(@request)
    get :show, id: checks(:one).to_param
    assert_response :success
  end

  test 'should get edit' do
    login_as_admin(@request)
    get :edit, id: checks(:one).to_param
    assert_response :success
  end

  test 'should update check' do
    login_as_admin(@request)
    put :update, id: checks(:one).to_param, check: {}
    assert_response :success
    # assert_redirected_to check_path(assigns(:check))
  end

  test 'should destroy check' do
    login_as_admin(@request)
    assert_difference('Check.count', -1) do
      delete :destroy, id: checks(:one).to_param
    end
    assert_redirected_to checks_path
  end
end
