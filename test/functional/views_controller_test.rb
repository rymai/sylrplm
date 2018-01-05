# frozen_string_literal: true

require 'test_helper'

class ViewsControllerTest < ActionController::TestCase
  test 'should get index' do
    login_as_admin(@request)
    get :index
    assert_response :success
    assert_not_nil assigns(:views)
  end

  test 'should get new' do
    login_as_admin(@request)
    get :new, view: { name: 'tout' }
    assert_response :success
  end

  test 'should create view' do
    login_as_admin(@request)
    assert_difference('View.count') do
      post :create, view: { name: 'tout' }
    end
    assert_response :success
  end

  test 'should show view' do
    login_as_admin(@request)
    get :show, id: views(:View_1).to_param
    assert_response :success
  end

  test 'should get edit' do
    login_as_admin(@request)
    get :edit, id: views(:View_1).to_param
    assert_response :success
  end

  test 'should update view' do
    login_as_admin(@request)
    put :update, id: views(:View_1).to_param, view: {}
    assert_response :success
  end

  test 'should destroy view' do
    login_as_admin(@request)
    assert_difference('View.count', -1) do
      delete :destroy, id: views(:View_1).to_param
    end
    assert_redirected_to views_path
  end
end
