# frozen_string_literal: true

require 'test_helper'

class UiColumnsControllerTest < ActionController::TestCase
  setup do
    @ui_column = ui_columns(:one)
  end

  test 'should get index' do
    get :index
    assert_response :success
    assert_not_nil assigns(:ui_columns)
  end

  test 'should get new' do
    get :new
    assert_response :success
  end

  test 'should create ui_column' do
    assert_difference('UiColumn.count') do
      post :create, ui_column: { description: @ui_column.description, editable: @ui_column.editable, ident: @ui_column.ident, title: @ui_column.title, type: @ui_column.type, type_editable: @ui_column.type_editable, type_editable_file: @ui_column.type_editable_file, type_show: @ui_column.type_show, visible_admin: @ui_column.visible_admin, visible_support: @ui_column.visible_support, visible_user: @ui_column.visible_user }
    end

    assert_redirected_to ui_column_path(assigns(:ui_column))
  end

  test 'should show ui_column' do
    get :show, id: @ui_column
    assert_response :success
  end

  test 'should get edit' do
    get :edit, id: @ui_column
    assert_response :success
  end

  test 'should update ui_column' do
    patch :update, id: @ui_column, ui_column: { description: @ui_column.description, editable: @ui_column.editable, ident: @ui_column.ident, title: @ui_column.title, type: @ui_column.type, type_editable: @ui_column.type_editable, type_editable_file: @ui_column.type_editable_file, type_show: @ui_column.type_show, visible_admin: @ui_column.visible_admin, visible_support: @ui_column.visible_support, visible_user: @ui_column.visible_user }
    assert_redirected_to ui_column_path(assigns(:ui_column))
  end

  test 'should destroy ui_column' do
    assert_difference('UiColumn.count', -1) do
      delete :destroy, id: @ui_column
    end

    assert_redirected_to ui_columns_path
  end
end
