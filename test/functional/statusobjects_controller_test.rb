# frozen_string_literal: true

require 'test_helper'

class StatusobjectsControllerTest < ActionController::TestCase
  test 'should get index' do
    login_as_admin(@request)
    get :index
    assert_response :success
    assert_not_nil assigns(:statusobjects)
  end

  test 'should get new' do
    login_as_admin(@request)
    get :new
    assert_response :success
  end

  test 'should create statusobject' do
    login_as_admin(@request)
    assert_difference('Statusobject.count') do
      post :create, statusobject: { forobject: 'part', name: 'good', rank: 1, typesobject_id: 1_045_584_116 }
    end
    assert_response :success
    # assert_redirected_to statusobject_path(assigns(:statusobject))
  end

  test 'should show statusobject' do
    login_as_admin(@request)
    get :show, id: statusobjects(:Statusobject_5).to_param
    assert_response :success
  end

  test 'should get edit' do
    login_as_admin(@request)
    get :edit, id: statusobjects(:Statusobject_5).to_param
    assert_response :success
  end

  test 'should update statusobject' do
    login_as_admin(@request)
    put :update, id: statusobjects(:Statusobject_5).to_param, statusobject: {}
    assert_response :success
  end

  test 'should destroy statusobject' do
    login_as_admin(@request)
    assert_difference('Statusobject.count', -1) do
      delete :destroy, id: statusobjects(:Statusobject_5).to_param
    end
    assert_redirected_to statusobjects_path
  end
end
