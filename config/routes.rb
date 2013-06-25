# require 'ruote_routing'

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

	resources :help, only: [:index]

	resource :sessions, only: [:new, :create, :destroy] do
		collection do
			get :login
			# get :new_account, as: 'new_account'
			post :create_account
		end
		member do
			get :choose_role
			get :activate
		end
		# get 'sessions/:id/activate', :controller => 'sessions', :action => 'activate'
	end
	get 'new_account' => 'sessions#new_account'

	# get 'sessions/login',	:controller => 'sessions', :action => 'login'

	resources :users do
		collection do
			get :empty_favori
		end
	end

	resources :datafiles
	resources :questions
	resources :accesses do
		collection do
			get :reset
		end
	end
	resources :roles_users
	resources :forum_items
	resources :forums
	resources :checks
	resources :sequences
	resources :volumes
	resources :roles
	resources :statusobjects
	resources :typesobjects
	resources :links do
		collection do
			get :reset
			get :empty_favori
		end
	end
# 	connect(
# 	'links/:id/edit_in_tree',
# 	:controller => 'links',
# 	:action => 'edit_in_tree',
# 	:conditions => { :method => :get })
# 	connect(
# 	'links/:id/update_in_tree',
# 	:controller => 'links',
# 	:action => 'update_in_tree')
# 	connect(
# 	'links/:id/remove_link',
# 	:controller => 'links',
# 	:action => 'remove_link')
# 	connect(
# 	'links/:id/add_favori',
# 	:controller => 'links',
# 	:action => 'add_favori',
# 	:conditions => { :method => :get })

# 	connect(
# 	'main/init_objects',
# 	:controller => 'main',
# 	:action => 'init_objects')

	get	'main/helpgeneral' => 'main#helpgeneral'

# 	connect(
# 	'datafiles/:id/show_file',
# 	:controller => 'datafiles',
# 	:action => 'show_file')
# 	connect(
# 	'datafiles/:id/download_file',
# 	:controller => 'datafiles',
# 	:action => 'download_file')
# 	connect(
# 	'datafiles/:id/del_fogdir',
# 	:controller => 'datafiles',
# 	:action => 'del_fogdir')

	resources :documents, has_many: :documents do
		collection do
			get :empty_favori
		end

		member do
			get :new_dup
		end
	end

# 	connect(
# 	'documents/:id/add_favori',
# 	:controller => 'documents',
# 	:action => 'add_favori',
# 	:conditions => { :method => :get })
# 	connect(
# 	'documents/:id/add_docs',
# 	:controller => 'documents',
# 	:action => 'add_docs')
# 	connect(
# 	'documents/:id/new_datafile',
# 	:controller => 'documents',
# 	:action => 'new_datafile')
# 	connect(
# 	'documents/:id/add_datafile',
# 	:controller => 'documents',
# 	:action => 'add_datafile')
# 	connect(
# 	'documents/:id/promote',
# 	:controller => 'documents',
# 	:action => 'promote',
# 	:conditions => { :method => :get })
# 	connect(
# 	'documents/:id/demote',
# 	:controller => 'documents',
# 	:action => 'demote',
# 	:conditions => { :method => :get })
# 	connect(
# 	'documents/:id/revise',
# 	:controller => 'documents',
# 	:action => 'revise',
# 	:conditions => { :method => :get })
# 	connect(
# 	'documents/:id/check_out',
# 	:controller => 'documents',
# 	:action => 'check_out')
# 	connect(
# 	'documents/:id/check_in',
# 	:controller => 'documents',
# 	:action => 'check_in')
# 	connect(
# 	'documents/:id/check_free',
# 	:controller => 'documents',
# 	:action => 'check_free')
# 	connect(
# 	'documents/:id/select_view',
# 	:controller => 'documents',
# 	:action => 'select_view')

	resources :parts, has_many: :documents do
		collection do
			get :empty_favori
		end

		member do
			get :new_dup
		end
	end
# 	connect(
# 	'parts/:id/add_favori',
# 	:controller => 'parts',
# 	:action => 'add_favori',
# 	:conditions => { :method => :get })
# 	connect(
# 	'parts/:id/promote',
# 	:controller => 'parts',
# 	:action => 'promote',
# 	:conditions => { :method => :get })
# 	connect(
# 	'parts/:id/demote',
# 	:controller => 'parts',
# 	:action => 'demote',
# 	:conditions => { :method => :get })
# 	connect(
# 	'parts/:id/revise',
# 	:controller => 'parts',
# 	:action => 'revise',
# 	:conditions => { :method => :get })
# 	connect(
# 	'parts/:id/add_parts',
# 	:controller => 'parts',
# 	:action => 'add_parts')
# 	connect(
# 	'parts/:id/add_docs',
# 	:controller => 'parts',
# 	:action => 'add_docs')
# 	connect(
# 	'parts/:id/remove_link',
# 	:controller => 'parts',
# 	:action => 'remove_link',
# 	:conditions => { :method => :get })
# 	connect(
# 	'parts/:id/new_forum',
# 	:controller => 'parts',
# 	:action => 'new_forum')
# 	connect(
# 	'parts/:id/add_forum',
# 	:controller => 'parts',
# 	:action => 'add_forum')
# 	connect(
# 	'parts/:id/promote',
# 	:controller => 'parts',
# 	:action => 'promote',
# 	:conditions => { :method => :get })
# 	connect(
# 	'parts/:id/demote',
# 	:controller => 'parts',
# 	:action => 'demote',
# 	:conditions => { :method => :get })
# 	connect(
# 	'parts/:id/select_view',
# 	:controller => 'parts',
# 	:action => 'select_view')
# 	connect(
# 	'parts/:id/new_datafile',
# 	:controller => 'parts',
# 	:action => 'new_datafile')
# 	connect(
# 	'parts/:id/add_datafile',
# 	:controller => 'parts',
# 	:action => 'add_datafile')

	resources :projects, has_many: :documents do
		collection do
			get :empty_favori
		end

		member do
			get :new_dup
		end
	end
# 	connect(
# 	'projects/:id/add_favori',
# 	:controller => 'projects',
# 	:action => 'add_favori',
# 	:conditions => { :method => :get })
# 	connect(
# 	'projects/:id/add_docs',
# 	:controller => 'projects',
# 	:action => 'add_docs')
# 	connect(
# 	'projects/:id/remove_link',
# 	:controller => 'projects',
# 	:action => 'remove_link',
# 	:conditions => { :method => :get })
# 	connect(
# 	'projects/:id/add_parts',
# 	:controller => 'projects',
# 	:action => 'add_parts')
# 	connect(
# 	'projects/:id/new_forum',
# 	:controller => 'projects',
# 	:action => 'new_forum')
# 	connect(
# 	'projects/:id/add_forum',
# 	:controller => 'projects',
# 	:action => 'add_forum')
# 	connect(
# 	'projects/:id/add_users',
# 	:controller => 'projects',
# 	:action => 'add_users')
# 	connect(
# 	'projects/:id/promote',
# 	:controller => 'projects',
# 	:action => 'promote',
# 	:conditions => { :method => :get })
# 	connect(
# 	'projects/:id/demote',
# 	:controller => 'projects',
# 	:action => 'demote',
# 	:conditions => { :method => :get })
# 	connect(
# 	'projects/:id/select_view',
# 	:controller => 'projects',
# 	:action => 'select_view')
# 	connect(
# 	'projects/:id/new_datafile',
# 	:controller => 'projects',
# 	:action => 'new_datafile')
# 	connect(
# 	'projects/:id/add_datafile',
# 	:controller => 'projects',
# 	:action => 'add_datafile')

	resources :customers, has_many: :documents do
		collection do
			get :empty_favori
		end

		member do
			get :new_dup
		end
	end
# 	connect(
# 	'customers/:id/add_favori',
# 	:controller => 'customers',
# 	:action => 'add_favori',
# 	:conditions => { :method => :get })
# 	connect(
# 	'customers/:id/add_docs',
# 	:controller => 'customers',
# 	:action => 'add_docs')
# 	connect(
# 	'customers/:id/remove_link',
# 	:controller => 'customers',
# 	:action => 'remove_link',
# 	:conditions => { :method => :get })
# 	connect(
# 	'customers/:id/add_parts',
# 	:controller => 'customers',
# 	:action => 'add_parts')
# 	connect(
# 	'customers/:id/add_projects',
# 	:controller => 'customers',
# 	:action => 'add_projects')
# 	connect(
# 	'customers/:id/new_forum',
# 	:controller => 'customers',
# 	:action => 'new_forum')
# 	connect(
# 	'customers/:id/add_forum',
# 	:controller => 'customers',
# 	:action => 'add_forum')
# 	connect(
# 	'customers/:id/select_view',
# 	:controller => 'customers',
# 	:action => 'select_view')
# 	connect(
# 	'customers/:id/new_datafile',
# 	:controller => 'customers',
# 	:action => 'new_datafile')
# 	connect(
# 	'customers/:id/add_datafile',
# 	:controller => 'customers',
# 	:action => 'add_datafile')

# 	connect(
# 	'users/:id/activate',
# 	:controller => 'users',
# 	:action => 'activate')

# 	connect(
# 	'users/:id/add_favori',
# 	:controller => 'users',
# 	:action => 'add_favori',
# 	:conditions => { :method => :get })

# 	connect(
# 	'users/browse',
# 	:controller => 'users',
# 	:action => 'browse')

# 	connect(
# 	'users/:id/reset_passwd',
# 	:controller => 'users',
# 	:action => 'reset_passwd')

# 	connect(
# 	'users/:id/account_edit',
# 	:controller => 'users',
# 	:action => 'account_edit')

# 	connect(
# 	'users/:id/account_update',
# 	:controller => 'users',
# 	:action => 'account_update')

# 	connect(
# 	'users/:id/account_edit_passwd',
# 	:controller => 'users',
# 	:action => 'account_edit_passwd')

	resources :groups
	resources :user_groups
	resources :group_definitions

# 	wfid_resources :errors

# 	wfid_resources :workitems

# 	wfid_resources :expressions

# 	connect(
# 	'expressions/:wfid/:expid/tree',
# 	:controller => 'expressions',
# 	:action => 'show_tree',
# 	:conditions => { :method => :get })

# 	connect(
# 	'expressions/:wfid/:expid/tree',
# 	:controller => 'expressions',
# 	:action => 'update_tree',
# 	:conditions => { :method => :put })

	resources :definitions do
		collection do
			get :new_process
		end
	end
# 	connect(
# 	'definitions/:id/tree.js',
# 	:controller => 'definitions',
# 	:action => 'tree')

	resources :processes

# 	connect(
# 	'processes/:id/tree.js',
# 	:controller => 'processes',
# 	:action => 'tree')

	resources :views
	resources :workitems
	resources :history

# # The priority is based upon order of creation: first created -> highest priority.

# # Sample of regular route:
# #   connect 'products/:id', :controller => 'catalog', :action => 'view'
# # Keep in mind you can assign values other than :controller and :action

# # Sample of named route:
# #   purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
# # This route can be invoked with purchase_url(:id => product.id)

# #connect 'forum_items/:forum_id/new_response', :controller => 'forum_items', :action => 'new_response'

# # Sample resource route (maps HTTP verbs to controller actions automatically):
# #   resources :products

# # Sample resource route with options:
# #   resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

# # Sample resource route with sub-resources:
# #   resources :products, :has_many => [ :comments, :sales ], :has_one => :seller

# # Sample resource route with more complex sub-resources
# #   resources :products do |products|
# #     products.resources :comments
# #     products.resources :sales, :collection => { :recent => :get }
# #   end

# # Sample resource route within a namespace:
# #   namespace :admin do |admin|
# #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
# #     admin.resources :products
# #   end

# # You can have the root of your site routed with root -- just remember to delete public/index.html.
# # root :controller => "welcome"

# # See how all your routes lay out with "rake routes"

# # Install the default routes as the lowest priority.
# # Note: These default routes make all actions in every controller accessible via GET requests. You should
# # consider removing or commenting them out if you're using named routes and resources.
# # connect ':controller/:action/:id'
# # connect ':controller/:action/:id.:format'

	# syl 17/11/2010 : route par defaut
	root :controller => "main", :action => "index"
end
