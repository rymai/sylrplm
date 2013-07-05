require 'ruote_routing'

SylRPLM::Application.routes.draw do
  resources :subscriptions

	resources :relations do
		collection do
      get :update_father
      get :update_child
		end
	end

	resources :notifications do
		member do
			get :notify
		end
	end

	resources :main, controller: 'main' do
		collection do
			get :news
			get :contacts
			get :tools
		end
	end
	get 'main/init_objects' => 'main#init_objects'
	get	'main/helpgeneral' => 'main#helpgeneral'

	resources :help, only: [:index]

	resource :sessions, only: [:new, :create, :destroy] do
		collection do
			get :login
			post :create_account
		end
		member do
			get :choose_role
			get :activate
		end
	end
	get 'new_account' => 'sessions#new_account'

	resources :users do
		collection do
			get :empty_favori
		end

		member do
			post :add_favori
			post :reset_passwd
			get :account_edit
			get :account_edit_passwd
			put :account_update
		end
	end

	resources :datafiles do
		member do
			get :show_file
			get :download_file
			get :del_fogdir # FIXME: Should be delete
		end
	end

	resources :accesses do
		collection do
			get :reset
		end
	end

	resources :questions
	resources :roles_users
	resources :forum_items
	resources :forums
	resources :checks
	resources :sequences
	resources :volumes
	resources :roles
	resources :statusobjects
	resources :typesobjects
	resources :groups
	resources :user_groups
	resources :group_definitions
	resources :views
	resources :workitems
	resources :history

	resources :links do
		collection do
			get :reset
			get :empty_favori
		end

		member do
			get :edit_in_tree
			post :update_in_tree # FIXME: Should be put
			get :remove_link # FIXME: Should be delete
			get :add_favori # FIXME: Should be post
		end
	end

	resources :documents do
		resources :documents

		collection do
			get :empty_favori
		end

		member do
			get :new_dup
			get :add_favori # FIXME: Should be post
			post :add_docs
			get :new_datafile
			post :add_datafile
			get :promote # FIXME: Should be put
			get :demote # FIXME: Should be delete
			get :revise # FIXME: Should be put
			get :check_in # FIXME: Should be put
			get :check_out # FIXME: Should be put
			get :check_free # FIXME: Should be put
			post :select_view
		end
	end

	resources :parts do
		resources :documents

		collection do
			get :empty_favori
		end

		member do
			get :new_dup
			post :add_favori
			get :promote # FIXME: Should be put
			get :demote # FIXME: Should be delete
			get :revise # FIXME: Should be put
			post :add_parts
			post :add_docs
			get :remove_link # FIXME: Should be delete
			post :new_forum
			post :add_forum
			get :new_datafile
			post :add_datafile
			post :select_view
		end
	end

	resources :projects do
		resources :documents

		collection do
			get :empty_favori
		end

		member do
			get :new_dup
			post :add_favori
			post :add_docs
			get :remove_link # FIXME: Should be delete
			post :add_parts
			post :new_forum
			post :add_forum
			post :add_users
			get :promote # FIXME: Should be put
			get :demote # FIXME: Should be delete
			post :select_view
			get :new_datafile
			post :add_datafile
		end
	end

	resources :customers do
		resources :documents

		collection do
			get :empty_favori
		end

		member do
			get :new_dup
			post :add_favori
			post :add_docs
			get :remove_link # FIXME: Should be delete
			post :add_parts
			post :add_projects
			post :new_forum
			post :add_forum
			post :select_view
			get :new_datafile
			post :add_datafile
		end
	end

	resources :definitions do
		collection do
			get :new_process
		end

		member do
			get :tree, :format => :js
		end
	end

	resources :processes do
		member do
			get :tree, :format => :js
		end
	end

	wfid_resources :errors
	wfid_resources :workitems
	wfid_resources :expressions

	get 'expressions/:wfid/:expid/tree' => 'expressions#show_tree'
	put 'expressions/:wfid/:expid/tree' => 'expressions#update_tree'

	root :to => 'main#index'
end
