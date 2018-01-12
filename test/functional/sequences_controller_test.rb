# frozen_string_literal: true

require 'test_helper'

class SequencesControllerTest < ActionController::TestCase
  test 'should get index' do
    login_as_admin(@request)
    get :index
    assert_response :success
    assert_not_nil assigns(:sequences)
  end

  test 'should get new' do
    login_as_admin(@request)
    get :new
    assert_response :success
  end

  test 'should create sequence' do
    login_as_admin(@request)
    assert_difference('Sequence.count') do
      post :create, sequence: { utility: 'utile', value: 'value' }
    end
    assert_response :success
    # assert_redirected_to sequence_path(assigns(:sequence))
  end

  test 'should show sequence' do
    login_as_admin(@request)
    get :show, id: sequences(:Sequence_1031227068).to_param
    assert_response :success
  end

  test 'should get edit' do
    login_as_admin(@request)
    get :edit, id: sequences(:Sequence_1031227068).to_param
    assert_response :success
  end

  test 'should update sequence' do
    login_as_admin(@request)
    put :update, id: sequences(:Sequence_1031227068).to_param, sequence: {}
    assert_response :success
  end

  test 'should destroy sequence' do
    login_as_admin(@request)
    assert_difference('Sequence.count', -1) do
      delete :destroy, id: sequences(:Sequence_1031227068).to_param
    end
    assert_redirected_to sequences_path
  end
end
