# frozen_string_literal: true

require 'test_helper'

class DatafilesControllerTest < ActionController::TestCase
  test 'should get index' do
    login_as_admin(@request)
    save_volumes
    get :index
    assert_response :success
    assert_not_nil assigns(:datafiles)
  end

  test 'should get new' do
    login_as_admin(@request)
    get :new, datafile: { owner_id: 1, ident: 'datafile01', projowner_id: 1, group_id: 1, volume_id: 1 }
    assert_response :success
  end

  test 'should create datafile' do
    login_as_admin(@request)
    assert_difference('Datafile.count') do
      post :create, datafile: { owner_id: 1, typesobject_id: '889037033', volume_id: 1, document_id: '15', revision: '1', ident: 'DF00000000140', group_id: '1', projowner_id: '1' }
    end
    assert_response :success
    # assert_redirected_to datafile_path(assigns(:datafile))
  end

  test 'should show datafile' do
    login_as_admin(@request)
    get :show, id: datafiles(:Datafile_14).to_param
    assert_response :success
  end

  test 'should get edit' do
    login_as_admin(@request)
    get :edit, id: datafiles(:Datafile_14).to_param
    assert_response :success
  end

  test 'should update datafile' do
    login_as_admin(@request)
    put :update, id: datafiles(:Datafile_14).to_param, datafile: {}
    assert_response :success
    # assert_redirected_to datafile_path(assigns(:datafile))
  end

  test 'should destroy datafile' do
    login_as_admin(@request)
    assert_difference('Datafile.count', -1) do
      delete :destroy, id: datafiles(:Datafile_14).to_param
    end
    assert_redirected_to datafiles_path
  end
end
