require 'test_helper'

class UiTablesControllerTest < ActionController::TestCase
  setup do
    @ui_table = ui_tables(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:ui_tables)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create ui_table" do
    assert_difference('UiTable.count') do
      post :create, ui_table: { description: @ui_table.description, ident: @ui_table.ident, pagination: @ui_table.pagination, title: @ui_table.title, type: @ui_table.type }
    end

    assert_redirected_to ui_table_path(assigns(:ui_table))
  end

  test "should show ui_table" do
    get :show, id: @ui_table
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @ui_table
    assert_response :success
  end

  test "should update ui_table" do
    patch :update, id: @ui_table, ui_table: { description: @ui_table.description, ident: @ui_table.ident, pagination: @ui_table.pagination, title: @ui_table.title, type: @ui_table.type }
    assert_redirected_to ui_table_path(assigns(:ui_table))
  end

  test "should destroy ui_table" do
    assert_difference('UiTable.count', -1) do
      delete :destroy, id: @ui_table
    end

    assert_redirected_to ui_tables_path
  end
end
