require File.dirname(__FILE__)+'/../test_helper'

class ProjectsControllerTest < ActionController::TestCase
	test "should get index" do
		login_as_admin(@request)
		get :index
		assert_response :success
		assert_not_nil assigns(:projects)
	end

	test "should get new" do
		login_as_admin(@request)
		get :new
		assert_response :success
	end

	test "should create project" do
		login_as_admin(@request)
		assert_difference('Project.count') do
			post :create, :project => { :ident=>"Projet01", :designation=>"designation",:owner_id=>1 ,:date=>"2015-10-11"}
		end
		assert_response :success
		#assert_redirected_to project_path(assigns(:project))
	end

	test "should show project" do
		login_as_admin(@request)
		get :show, :id => projects(:Project_2).to_param
		assert_response :success
	end

	test "should get edit" do
		login_as_admin(@request)
		get :edit, :id => projects(:Project_2).to_param
		assert_response :success
	end

	test "should update project" do
		login_as_admin(@request)
		put :update, :id => projects(:Project_2).to_param, :project => { }
		assert_response :success
		#assert_redirected_to project_path(assigns(:project))
	end

	test "should destroy project" do
		login_as_admin(@request)
		assert_difference('Project.count', -1) do
			delete :destroy, :id => projects(:Project_2).to_param
		end

		assert_redirected_to projects_path
	end
end
