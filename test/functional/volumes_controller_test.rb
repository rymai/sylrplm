require 'test_helper'

class VolumesControllerTest < ActionController::TestCase
  test "should get index" do
    login_as_admin(@request)
    get :index
    assert_response :success
    assert_not_nil assigns(:volumes)
  end

  test "should get new" do
	login_as_admin(@request)
    get :new, :volume=>{:name=>"volume1",:protocol=>"file_system"}
    assert_response :success
  end

  test "should create volume" do
    login_as_admin(@request)
    assert_difference('Volume.count') do
      post :create, :volume => {:name=>"volume1",:protocol=>"file_system"}
    end
     assert_response :success
     #assert_redirected_to volume_path(assigns(:volume))
  end

  test "should show volume" do
    login_as_admin(@request)
    get :show, :id => volumes(:Volume_2).to_param
    assert_response :success
  end

  test "should get edit" do
    login_as_admin(@request)
    get :edit, :id => volumes(:Volume_2).to_param
   assert_response :success
  end

  test "should update volume" do
    login_as_admin(@request)
    put :update, :id => volumes(:Volume_2).to_param, :volume => { }
   assert_response :success
  end

  test "should destroy volume" do
    login_as_admin(@request)
    post :create, :volume => {:name=>"volume1",:protocol=>"file_system"}
    assert_difference('Volume.count', -1) do
      delete :destroy, :id => Volume.find_by_name("volume1").to_param
    end
    assert_redirected_to volumes_path
  end
end
