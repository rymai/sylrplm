# frozen_string_literal: true

require File.dirname(__FILE__) + '/../test_helper'

class DocumentsControllerTest < ActionController::TestCase
  test 'should get index' do
    login_as_admin(@request)
    get :index
    assert_response :success
    assert_not_nil assigns(:documents)
  end

  test 'should get new' do
    login_as_admin(@request)
    get :new
    assert_response :success
  end

  test 'should create document' do
    login_as_admin(@request)
    assert_difference('Document.count') do
      post :create, document: { owner_id: 1, ident: 'DOC00123', designation: 'nouveau doc', date: '2015-10-10' }
    end
    assert_response :success
    # assert_redirected_to document_path(assigns(:document))
  end

  test 'should show document' do
    login_as_admin(@request)
    get :show, id: documents(:Document_3).to_param
    assert_response :success
  end

  test 'should get edit' do
    login_as_admin(@request)
    get :edit, id: documents(:Document_3).to_param
    assert_response :success
  end

  test 'should update document' do
    login_as_admin(@request)
    put :update, id: documents(:Document_3).to_param, document: {}
    assert_response :success
    # assert_redirected_to document_path(assigns(:document))
  end

  test 'should destroy document' do
    login_as_admin(@request)
    post :create, document: { owner_id: 1, ident: 'DOC00123', designation: 'nouveau doc', date: '2015-10-10' }
    assert_difference('Document.count', -1) do
      delete :destroy, id: Document.find_by_ident('DOC00123').to_param
    end
    assert_redirected_to documents_path
  end
end
