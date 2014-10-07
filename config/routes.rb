require 'ruote_routing'

ActionController::Routing::Routes.draw do |map|
  map.resources :subscriptions


# syl 17/11/2010 : route par defaut
	map.root :controller => "main", :action => "index"
	map.resources :main, :controller => "main", :collection => { :news => :get, :contacts => :get, :tools => :get, :helpgeneral => :get}
	#desactivate because connection is mandatory for this action: map.root :controller => "workitems", :action => "index"

	map.resources :accesses, :collection => { :reset => :get}, :member=> {:new_dup => :get}

	map.resources :checks

	map.resources :customers, :has_many => :documents, :collection => { :empty_favori => :get }, :member=> {:edit_lifecycle => :get,:new_dup => :get}
	map.connect(
	'customers/:id/add_favori',
	:controller => 'customers',
	:action => 'add_favori',
	:conditions => { :method => :get })
	map.connect(
	'customers/:id/add_objects',
	:controller => 'customers',
	:action => 'add_objects')
	map.connect(
	'customers/:id/remove_link',
	:controller => 'customers',
	:action => 'remove_link',
	:conditions => { :method => :get })
	map.connect(
	'customers/:id/new_forum',
	:controller => 'customers',
	:action => 'new_forum')
	map.connect(
	'customers/:id/add_forum',
	:controller => 'customers',
	:action => 'add_forum')
	map.connect(
	'customers/:id/select_view',
	:controller => 'customers',
	:action => 'select_view')
	map.connect(
	'customers/:id/new_datafile',
	:controller => 'customers',
	:action => 'new_datafile')
	map.connect(
	'customers/:id/add_datafile',
	:controller => 'customers',
	:action => 'add_datafile')
	map.connect(
	'customers/:id/update_lifecycle',
	:controller => 'customers',
	:action => 'update_lifecycle')
	map.connect(
	'customers/:id/show_design',
	:controller => 'customers',
	:action => 'show_design')
	map.connect(
	'customers/:id/update_type',
	:controller => 'customers',
	:action => 'update_type')

	map.resources :datafiles
	map.connect(
	'datafiles/:id/show_file',
	:controller => 'datafiles',
	:action => 'show_file')
	map.connect(
	'datafiles/:id/download_file',
	:controller => 'datafiles',
	:action => 'download_file')
	map.connect(
	'datafiles/:file_id/del_sylrplm_file',
	:controller => 'datafiles',
	:action => 'del_sylrplm_file')
	map.connect(
	'datafiles/:id/update_type',
	:controller => 'datafiles',
	:action => 'update_type')

	map.resources :definitions, :collection => { :new_process => :get}, :member=> {:new_dup => :get}
	map.connect(
	'definitions/:id/tree.js',
	:controller => 'definitions',
	:action => 'tree')

	map.resources :documents, :has_many => :documents, :collection => { :empty_favori => :get }, :member=> {:edit_lifecycle => :get, :new_dup => :get}
	map.connect(
	'documents/:id/add_favori',
	:controller => 'documents',
	:action => 'add_favori',
	:conditions => { :method => :get })
	map.connect(
	'documents/:id/add_objects',
	:controller => 'documents',
	:action => 'add_objects')
	map.connect(
	'documents/:id/new_datafile',
	:controller => 'documents',
	:action => 'new_datafile')
	map.connect(
	'documents/:id/add_datafile',
	:controller => 'documents',
	:action => 'add_datafile')
	map.connect(
	'documents/:id/promote',
	:controller => 'documents',
	:action => 'promote',
	:conditions => { :method => :get })
	map.connect(
	'documents/:id/demote',
	:controller => 'documents',
	:action => 'demote',
	:conditions => { :method => :get })
	map.connect(
	'documents/:id/revise',
	:controller => 'documents',
	:action => 'revise',
	:conditions => { :method => :get })
	map.connect(
	'documents/:id/check_out',
	:controller => 'documents',
	:action => 'check_out')
	map.connect(
	'documents/:id/check_in',
	:controller => 'documents',
	:action => 'check_in')
	map.connect(
	'documents/:id/check_free',
	:controller => 'documents',
	:action => 'check_free')
	map.connect(
	'documents/:id/select_view',
	:controller => 'documents',
	:action => 'select_view')
	map.connect(
	'documents/:id/update_lifecycle',
	:controller => 'documents',
	:action => 'update_lifecycle')
	map.connect(
	'documents/:id/new_forum',
	:controller => 'documents',
	:action => 'new_forum')
	map.connect(
	'documents/:id/add_forum',
	:controller => 'documents',
	:action => 'add_forum')
	map.connect(
	'documents/:id/show_design',
	:controller => 'documents',
	:action => 'show_design')
	map.connect(
	'documents/:id/update_type',
	:controller => 'documents',
	:action => 'update_type')

	map.connect(
	'expressions/:wfid/:expid/tree',
	:controller => 'expressions',
	:action => 'show_tree',
	:conditions => { :method => :get })
	map.connect(
	'expressions/:wfid/:expid/tree',
	:controller => 'expressions',
	:action => 'update_tree',
	:conditions => { :method => :put })

	map.resources :forums, :member=> {:edit_lifecycle => :get}
	map.connect(
	'forums/:id/update_lifecycle',
	:controller => 'forums',
	:action => 'update_lifecycle')
	map.connect(
	'forums/:id/update_type',
	:controller => 'forums',
	:action => 'update_type')
	map.resources :forum_items

	map.resources :groups, :member=> {:new_dup => :get}
	map.connect(
	'groups/:id/select_view',
	:controller => 'groups',
	:action => 'select_view')

	map.resources :group_definitions

	map.resources :help, :only => [:index]

	map.resources :history

	map.resources :links, :collection => { :reset => :get, :empty_favori => :get}
	map.connect(
	'links/:id/edit_in_tree',
	:controller => 'links',
	:action => 'edit_in_tree',
	:conditions => { :method => :get })
	map.connect(
	'links/:id/update_in_tree',
	:controller => 'links',
	:action => 'update_in_tree')
	map.connect(
	'links/:id/remove_link',
	:controller => 'links',
	:action => 'remove_link')
	map.connect(
	'links/:id/add_favori',
	:controller => 'links',
	:action => 'add_favori',
	:conditions => { :method => :get })

	map.resources :notifications, :member => { :notify => :get }

	map.resources :parts, :has_many => :documents, :collection => { :empty_favori => :get}, :member=> {:edit_lifecycle => :get,:new_dup => :get}
	map.connect(
	'parts/:id/add_favori',
	:controller => 'parts',
	:action => 'add_favori',
	:conditions => { :method => :get })
	map.connect(
	'parts/:id/promote',
	:controller => 'parts',
	:action => 'promote',
	:conditions => { :method => :get })
	map.connect(
	'parts/:id/demote',
	:controller => 'parts',
	:action => 'demote',
	:conditions => { :method => :get })
	map.connect(
	'parts/:id/revise',
	:controller => 'parts',
	:action => 'revise',
	:conditions => { :method => :get })
	map.connect(
	'parts/:id/add_objects',
	:controller => 'parts',
	:action => 'add_objects')
	map.connect(
	'parts/:id/remove_link',
	:controller => 'parts',
	:action => 'remove_link',
	:conditions => { :method => :get })
	map.connect(
	'parts/:id/new_forum',
	:controller => 'parts',
	:action => 'new_forum')
	map.connect(
	'parts/:id/add_forum',
	:controller => 'parts',
	:action => 'add_forum')
	map.connect(
	'parts/:id/promote',
	:controller => 'parts',
	:action => 'promote',
	:conditions => { :method => :get })
	map.connect(
	'parts/:id/demote',
	:controller => 'parts',
	:action => 'demote',
	:conditions => { :method => :get })
	map.connect(
	'parts/:id/select_view',
	:controller => 'parts',
	:action => 'select_view')
	map.connect(
	'parts/:id/new_datafile',
	:controller => 'parts',
	:action => 'new_datafile')
	map.connect(
	'parts/:id/add_datafile',
	:controller => 'parts',
	:action => 'add_datafile')
	map.connect(
	'parts/:id/update_lifecycle',
	:controller => 'parts',
	:action => 'update_lifecycle')
	map.connect(
	'parts/:id/show_design',
	:controller => 'parts',
	:action => 'show_design')
	map.connect(
	'parts/:id/update_type',
	:controller => 'parts',
	:action => 'update_type')

	map.resources :processes
	map.connect(
	'processes/:id/tree.js',
	:controller => 'processes',
	:action => 'tree')

	map.resources :projects, :has_many => :documents, :collection => { :empty_favori => :get}, :member=> {:edit_lifecycle => :get,:new_dup => :get}
	map.connect(
	'projects/:id/add_favori',
	:controller => 'projects',
	:action => 'add_favori',
	:conditions => { :method => :get })
	map.connect(
	'projects/:id/add_objects',
	:controller => 'projects',
	:action => 'add_objects')
	map.connect(
	'projects/:id/remove_link',
	:controller => 'projects',
	:action => 'remove_link',
	:conditions => { :method => :get })
	map.connect(
	'projects/:id/new_forum',
	:controller => 'projects',
	:action => 'new_forum')
	map.connect(
	'projects/:id/add_forum',
	:controller => 'projects',
	:action => 'add_forum')
	map.connect(
	'projects/:id/promote',
	:controller => 'projects',
	:action => 'promote',
	:conditions => { :method => :get })
	map.connect(
	'projects/:id/demote',
	:controller => 'projects',
	:action => 'demote',
	:conditions => { :method => :get })
	map.connect(
	'projects/:id/select_view',
	:controller => 'projects',
	:action => 'select_view')
	map.connect(
	'projects/:id/new_datafile',
	:controller => 'projects',
	:action => 'new_datafile')
	map.connect(
	'projects/:id/add_datafile',
	:controller => 'projects',
	:action => 'add_datafile')
	map.connect(
	'projects/:id/update_lifecycle',
	:controller => 'projects',
	:action => 'update_lifecycle')
	map.connect(
	'projects/:id/show_design',
	:controller => 'projects',
	:action => 'show_design')
	map.connect(
	'projects/:id/update_type',
	:controller => 'projects',
	:action => 'update_type')

	map.resources :relations, :member=> {:new_dup => :get}
	map.connect(
	'relations/update_father',
	:controller => 'relations',
	:action => 'update_father')
	map.connect(
	'relations/update_child',
	:controller => 'relations',
	:action => 'update_child')
	map.connect(
	'relations/:id/update_type',
	:controller => 'relations',
	:action => 'update_type')

	map.resources :questions

	map.resources :roles, :member=> {:new_dup => :get}
	map.connect(
	'roles/:id/select_view',
	:controller => 'roles',
	:action => 'select_view')

	map.resources :roles_users

	map.resources :sequences, :member=> {:new_dup => :get}

	map.resource :sessions, :only => [:new, :create , :destroy]
	#map.resource :sessions, :only => [:new, :create, :update, :destroy], :member => { :choose_role => :get }
	# map.resource :sessions, :only => [:new, :create, :update, :destroy]
	map.new_account 'sessions/new_account', controller: 'sessions', action: 'new_account', conditions: { method: :get }
	map.create_account 'sessions/create_account', controller: 'sessions', action: 'create_account', conditions: { method: :post }
	map.connect(
	'sessions/login',
	:controller => 'sessions',
	:action => 'login')
	map.connect(
	'sessions/:id/activate',
	:controller => 'sessions',
	:action => 'activate')

	map.resources :statusobjects, :member=> {:new_dup => :get}
	map.connect(
	'statusobjects/:id/update_type',
	:controller => 'statusobjects',
	:action => 'update_type')

	map.resources :subscriptions, :member=> {:new_dup => :get}

	map.resources :typesobjects, :member=> {:new_dup => :get}

	map.resources :users, :collection => { :empty_favori => :get }, :member=> {:new_dup => :get}
	map.connect(
	'users/:id/activate',
	:controller => 'users',
	:action => 'activate')
	map.connect(
	'users/:id/add_favori',
	:controller => 'users',
	:action => 'add_favori',
	:conditions => { :method => :get })
	map.connect(
	'users/browse',
	:controller => 'users',
	:action => 'browse')
	map.connect(
	'users/:id/reset_passwd',
	:controller => 'users',
	:action => 'reset_passwd')
	map.connect(
	'users/:id/account_edit',
	:controller => 'users',
	:action => 'account_edit')
	map.connect(
	'users/:id/account_update',
	:controller => 'users',
	:action => 'account_update')
	map.connect(
	'users/:id/account_edit_passwd',
	:controller => 'users',
	:action => 'account_edit_passwd')
	map.connect(
	'users/:id/update_type',
	:controller => 'users',
	:action => 'update_type')

	map.resources :user_groups

	map.resources :views, :member=> {:new_dup => :get}

	map.resources :volumes, :member=> {:new_dup => :get}

	map.resources :workitems

	map.wfid_resources :errors

	map.wfid_resources :workitems

	map.wfid_resources :expressions

# The priority is based upon order of creation: first created -> highest priority.

# Sample of regular route:
#   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
# Keep in mind you can assign values other than :controller and :action

# Sample of named route:
#   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
# This route can be invoked with purchase_url(:id => product.id)

#map.connect 'forum_items/:forum_id/new_response', :controller => 'forum_items', :action => 'new_response'

# Sample resource route (maps HTTP verbs to controller actions automatically):
#   map.resources :products

# Sample resource route with options:
#   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

# Sample resource route with sub-resources:
#   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller

# Sample resource route with more complex sub-resources
#   map.resources :products do |products|
#     products.resources :comments
#     products.resources :sales, :collection => { :recent => :get }
#   end

# Sample resource route within a namespace:
#   map.namespace :admin do |admin|
#     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
#     admin.resources :products
#   end

# You can have the root of your site routed with map.root -- just remember to delete public/index.html.
# map.root :controller => "welcome"

# See how all your routes lay out with "rake routes"

# Install the default routes as the lowest priority.
# Note: These default routes make all actions in every controller accessible via GET requests. You should
# consider removing or commenting them out if you're using named routes and resources.
# map.connect ':controller/:action/:id'
# map.connect ':controller/:action/:id.:format'
end