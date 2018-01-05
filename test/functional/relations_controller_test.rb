# frozen_string_literal: true

require 'test_helper'

class RelationsControllerTest < ActionController::TestCase
  test 'should get index' do
    login_as_admin(@request)
    get :index
    assert_response :success
    assert_not_nil assigns(:relations)
  end

  test 'should get new' do
    login_as_admin(@request)
    get :new
    assert_response :success
  end

  test 'should create relation' do
    login_as_admin(@request)
    assert_difference('Relation.count') do
      post :create, relation: { father_typesobject_id: 1_045_584_123, child_typesobject_id: 1_045_584_116, paste_way: 'manual', cardin_occur_min: 0, cardin_occur_max: -1, cardin_use_min: 0, cardin_use_max: -1,
                                typesobject_id: 502_955_464, name: 'relation01', father_plmtype: 'part', child_plmtype: 'part' }, fonct: { current: 'create' }
    end
    assert_response :success
    # assert_redirected_to relation_path(assigns(:relation))
  end

  test 'should show relation' do
    login_as_admin(@request)
    get :show, id: relations(:Relation_1).to_param
    assert_response :success
  end

  test 'should get edit' do
    login_as_admin(@request)
    get :edit, id: relations(:Relation_1).to_param
    assert_response :success
  end

  test 'should update relation' do
    login_as_admin(@request)
    put :update, id: relations(:Relation_1).to_param, relation: {}
    assert_response :success
  end

  test 'should destroy relation' do
    login_as_admin(@request)
    assert_difference('Relation.count', -1) do
      delete :destroy, id: relations(:Relation_1).to_param
    end
    assert_redirected_to relations_path
  end
end
