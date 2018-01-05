# frozen_string_literal: true

require 'test_helper'

class QuestionsControllerTest < ActionController::TestCase
  test 'should get index' do
    login_as_admin(@request)
    get :index
    assert_response :success
    assert_nil assigns(:questions)
  end

  test 'should get new' do
    login_as_admin(@request)
    get :new
    assert_response :success
  end

  test 'should create question' do
    login_as_admin(@request)
    assert_difference('Question.count') do
      post :create, question: { question: 'question' }
    end
    assert_response :success
  end

  test 'should show question' do
    login_as_admin(@request)
    get :show, id: questions(:one).to_param
    assert_response :success
  end

  test 'should get edit' do
    login_as_admin(@request)
    get :edit, id: questions(:one).to_param
    assert_response :success
  end

  test 'should update question' do
    login_as_admin(@request)
    put :update, id: questions(:one).to_param, question: {}
    assert_response :success
  end

  test 'should destroy question' do
    login_as_admin(@request)
    assert_difference('Question.count', -1) do
      delete :destroy, id: questions(:one).to_param
    end
    assert_redirected_to questions_path
  end
end
