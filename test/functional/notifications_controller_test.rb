# frozen_string_literal: true

require 'test_helper'

class NotificationsControllerTest < ActionController::TestCase
  test 'should get index' do
    login_as_admin(@request)
    get :index
    assert_response :success
    assert_not_nil assigns(:notifications)
  end

  test 'should get new' do
    login_as_admin(@request)
    get :new
    assert_response :success
  end

  test 'should create notification' do
    login_as_admin(@request)
    assert_difference('Notification.count') do
      post :create, notification: { forobject_type: 'part', forobject_id: 1, event_date: '2012-04-20', event_type: 'MyText', responsible_id: 1, notify_date: '2011-06-23' }
    end
    assert_response :success
    # assert_redirected_to notification_path(assigns(:notification))
  end

  test 'should show notification' do
    login_as_admin(@request)
    get :show, id: notifications(:one).to_param
    assert_response :success
  end

  test 'should get edit' do
    login_as_admin(@request)
    get :edit, id: notifications(:one).to_param
    assert_response :success
  end

  test 'should update notification' do
    login_as_admin(@request)
    put :update, id: notifications(:one).to_param, notification: {}
    assert_response :success
    # assert_redirected_to notification_path(assigns(:notification))
  end

  test 'should destroy notification' do
    login_as_admin(@request)
    assert_difference('Notification.count', -1) do
      delete :destroy, id: notifications(:one).to_param
    end
    assert_redirected_to notifications_path
  end
end
