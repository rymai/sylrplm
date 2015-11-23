require 'test_helper'

class LinksControllerTest < ActionController::TestCase
	test "should get index" do
		login_as_admin(@request)
		get :index
		assert_response :success
		assert_not_nil assigns(:links)
	end

	test "should get new" do
		login_as_admin(@request)
		get :new
		assert_response :success
	end

	test "should create link" do
		login_as_admin(@request)
		assert_difference('Link.count') do
			post :create, :link => { :father_plmtype=>"document",:child_plmtype=>"document", :father_id=>3, :child_id=>5, :relation_id=>27, :owner_id=>1, :group_id=>1, :projowner_id=>1}
		end
		assert_response :success
	#assert_redirected_to link_path(assigns(:link))
	end

	test "should show link" do
		login_as_admin(@request)
		get :show, :id => links(:Link_174).to_param
		assert_response :success
	end

	test "should get edit" do
		login_as_admin(@request)
		get :edit, :id => links(:Link_174).to_param
		assert_response :success
	end

	test "should destroy link" do
		login_as_admin(@request)
		assert_difference('Link.count', -1) do
			delete :destroy, :id => links(:Link_174).to_param
		end
		assert_redirected_to links_path
	end
end
