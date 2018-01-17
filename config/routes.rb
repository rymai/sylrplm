#rails 4 ActionController::Routing::Routes.draw do |map|
Rails.application.routes.draw do


###get 'ajax/:action', to: 'ajax#:action', :defaults => { :format => 'json' }

#rails2 map.resources :subscriptions
	resources :subscriptions

	#route par defaut
	#rails2 map.root :controller => "main", :action => "index"
	root :to => 'main#index'

	#rails2 map.resources :main, :controller => "main", :collection => { :news => :get, :contacts => :get, :tools => :get, :helpgeneral => :get, :how_to => :get}
	resources :main do
	#controller :main
		collection do
			get :news
			get :contacts
			get :tools
			get :helpgeneral
			get :how_to
		end
	end

	#rails2 map.resources :accesses, :collection => { :reset => :get}, :member=> {:new_dup => :get}
	resources :accesses do
		member do
			get :new_dup
		end
		collection do
			get :reset
		end
	end

	#rails2 map.resources :checks
	resources :checks

resources :contacts do
        collection do
            get :export
        end
    end
    #rails2 map.connect(    'forums/:id/update_lifecycle',  :controller => 'forums',    :action => 'update_lifecycle')
   match 'contacts/index_execute', :to => 'contacts#index_execute', via: [:get, :post]
   match 'contacts/update_type', :to => 'contacts#update_type', via: [:get, :post]

	#rails2 map.resources :customers, :has_many => :documents, :collection => { :empty_clipboard => :get }, :member=> {:edit_lifecycle => :get,:new_dup => :get}
	resources :customers do
		member do
			get :edit_lifecycle
			get :new_dup
		end
		collection do
			get :empty_clipboard
			get :export
		end
	end

	#rails2 map.connect(	'customers/index_execute',	:controller => 'customers',	:action => 'index_execute')
	match 'customers/index_execute', :to => 'customers#index_execute', via: [:get, :post]

	#rails2 map.connect(	'customers/:id/add_clipboard',	:controller => 'customers',	:action => 'add_clipboard',	:conditions => { :method => :get })
	match 'customers/:id/add_clipboard', :to => 'customers#add_clipboard', via: [:get, :post], as: :add_clipboard_customer

	#rails2 map.connect(	'customers/:id/add_objects',	:controller => 'customers',	:action => 'add_objects')
	match 'customers/:id/add_objects', :to => 'customers#add_objects', via: [:patch]

	#rails2 map.connect(	'customers/:id/add_link_objects',	:controller => 'customers',	:action => 'add_link_objects')
	match 'customers/:id/add_link_objects', :to => 'customers#add_link_objects', via:  [:patch]

	#rails2 map.connect(	'customers/:id/remove_link',	:controller => 'customers',	:action => 'remove_link',	:conditions => { :method => :get })
	match 'customers/:id/remove_link', :to => 'customers#remove_link', via: [:get, :post]

	#rails2 map.connect(	'customers/:id/new_forum',	:controller => 'customers',	:action => 'new_forum')
	match 'customers/:id/new_forum', :to => 'customers#new_forum', via: [:patch]

	#rails2 map.connect(	'customers/:id/add_forum',	:controller => 'customers',	:action => 'add_forum')
	match 'customers/:id/add_forum', :to => 'customers#add_forum', via: [:get, :post]

	#rails2 map.connect(	'customers/:id/select_view',	:controller => 'customers',	:action => 'select_view')
	match 'customers/:id/select_view', :to => 'customers#select_view', via:[:patch]

	#rails2 map.connect(	'customers/:id/new_datafile',	:controller => 'customers',	:action => 'new_datafile')
	match 'customers/:id/new_datafile', :to => 'customers#new_datafile', via: [:get, :post]

	#rails2 map.connect(	'customers/:id/add_datafile',	:controller => 'customers',	:action => 'add_datafile')
	match 'customers/:id/add_datafile', :to => 'customers#add_datafile', via: [:get, :post]

	#rails2 map.connect(	'customers/:id/update_lifecycle',	:controller => 'customers',	:action => 'update_lifecycle')
	match 'customers/:id/update_lifecycle', :to => 'customers#update_lifecycle', via: [:get, :post]

	#rails2 map.connect(	'customers/:id/show_design',	:controller => 'customers',	:action => 'show_design')
	match 'customers/:id/show_design', :to => 'customers#show_design', via: [:get, :post]

	#rails2 map.connect(	'customers/:id/update_type',	:controller => 'customers',	:action => 'update_type')
	match 'customers/:id/update_type', :to => 'customers#update_type', via: [:get, :post]

	#rails2 map.resources :datafiles
	resources :datafiles do
		member do
		end
		collection do
			get :export
		end
	end

	#rails2 map.connect(	'datafiles/:id/show_file',	:controller => 'datafiles',	:action => 'show_file')
	match 'datafiles/:id/show_file', :to => 'datafiles#show_file', via: [:get, :post]

	#rails2 map.connect(	'datafiles/:id/download_file',	:controller => 'datafiles',	:action => 'download_file')
	match 'datafiles/:id/download_file', :to => 'datafiles#download_file', via: [:get, :post]

	#rails2 map.connect(	'datafiles/:file_id/del_sylrplm_file',	:controller => 'datafiles',	:action => 'del_sylrplm_file')
	match 'datafiles/:id/del_sylrplm_file', :to => 'datafiles#del_sylrplm_file', via: [:get, :post]

	#rails2 map.connect(	'datafiles/:id/update_type',	:controller => 'datafiles',	:action => 'update_type')
	match 'datafiles/:id/update_type', :to => 'datafiles#update_type', via: [:get, :post]

	#rails2 map.resources :definitions, :collection => { :new_process => :get}, :member=> {:new_dup => :get}
	resources :definitions do
		member do
			get :new_dup
		end
		collection do
			get :new_process
			get :export
		end
	end
	#rails2map.connect(	'definitions/index_execute',	:controller => 'definitions',	:action => 'index_execute')
	match 'definitions/index_execute', :to => 'definitions#index_execute', via: [:get, :post]

	#rails2map.connect(	'definitions/:id/tree.js',	:controller => 'definitions',	:action => 'tree')
	match 'definitions/tree', :to => 'definitions#tree', via: [:get, :post]

	#rails2 map.resources :documents, :has_many => :documents, :collection => { :empty_clipboard => :get }, :member=> {:edit_lifecycle => :get, :new_dup => :get}
	resources :documents do
		member do
			get :edit_lifecycle
			get :new_dup
		end
		collection do
			get :empty_clipboard
			get :export
		end
	end
	#rails2 map.connect(	'documents/index_execute',	:controller => 'documents',	:action => 'index_execute')
	match 'documents/index_execute', :to => 'documents#index_execute', via: [:get, :post]

	#rails2 map.connect(	'documents/:id/add_clipboard',	:controller => 'documents',	:action => 'add_clipboard',	:conditions => { :method => :get })
	match 'documents/:id/add_clipboard', :to => 'documents#add_clipboard', via: [:get, :post], as: :add_clipboard_document

	#rails2 map.connect(	'documents/:id/add_objects',	:controller => 'documents',	:action => 'add_objects')
	match 'documents/:id/add_objects', :to => 'documents#add_objects', via: [:patch]

	#rails2 map.connect(	'documents/:id/add_link_objects',	:controller => 'documents',	:action => 'add_link_objects')
	match 'documents/:id/add_link_objects', :to => 'documents#add_link_objects', via:  [:patch]

	#rails2 map.connect(	'documents/:id/new_datafile',	:controller => 'documents',	:action => 'new_datafile')
	match 'documents/:id/new_datafile', :to => 'documents#new_datafile', via: [:get, :post]

	#rails2 map.connect(	'documents/:id/add_datafile',	:controller => 'documents',	:action => 'add_datafile')
	match 'documents/:id/add_datafile',	 :to => 'documents#add_datafile', via: [:get, :post]

	#rails2 map.connect(	'documents/:id/promote',	:controller => 'documents',	:action => 'promote',	:conditions => { :method => :get })
	match 'documents/:id/promote', :to => 'documents#promote', via: [:get, :post]

	#rails2 map.connect(	'documents/:id/demote',	:controller => 'documents',	:action => 'demote',	:conditions => { :method => :get })
	match 	'documents/:id/demote', :to => 'documents#demote', via: [:get, :post]

	#rails2 map.connect(	'documents/:id/revise',	:controller => 'documents',	:action => 'revise',	:conditions => { :method => :get })
	match 'documents/:id/revise', :to => 'documents#revise', via: [:get, :post]

	#rails2 map.connect(	'documents/:id/check_out',	:controller => 'documents',	:action => 'check_out')
	match 'documents/:id/check_out',	 :to => 'documents#check_out', via: [:get, :post]

	#rails2 map.connect(	'documents/:id/check_in',	:controller => 'documents',	:action => 'check_in')
	match 'documents/:id/check_in', :to => 'documents#check_in', via: [:get, :post]

	#rails2 map.connect(	'documents/:id/check_free',	:controller => 'documents',	:action => 'check_free')
	match 'documents/:id/check_free',	 :to => 'documents#check_free', via: [:get, :post]

	#rails2 map.connect(	'documents/:id/select_view',	:controller => 'documents',	:action => 'select_view')
	match 'documents/:id/select_view', :to => 'documents#select_view', via: [:patch]

	#rails2 map.connect(	'documents/:id/update_lifecycle',	:controller => 'documents',	:action => 'update_lifecycle')
	match 	'documents/:id/update_lifecycle', :to => 'documents#update_lifecycle', via: [:get, :post]

	#rails2 map.connect(	'documents/:id/new_forum',	:controller => 'documents',	:action => 'new_forum')
	match 'documents/:id/new_forum',	 :to => 'documents#new_forum', via: [:patch]

	#rails2 map.connect(	'documents/:id/add_forum',	:controller => 'documents',	:action => 'add_forum')
	match 'documents/:id/add_forum', :to => 'documents#add_forum', via: [:get, :post]

	#rails2 map.connect(	'documents/:id/show_design',	:controller => 'documents',	:action => 'show_design')
	match 	'documents/:id/show_design', :to => 'documents#show_design', via: [:get, :post]

	#rails2 map.connect(	'documents/:id/update_type',	:controller => 'documents',	:action => 'update_type')
	match 'documents/:id/update_type', :to => 'documents#update_type', via: [:get, :post]

	resources :expressions
	#expressions
	#rails2 map.connect(	'expressions/:wfid/:expid/tree',	:controller => 'expressions',	:action => 'show_tree',:conditions => { :method => :get })
	match 'expressions/:wfid/:expid/tree', :to => 'expressions#show_tree', via: [:get, :post]

	match 'expressions/:wfid/:expid/show', :to => 'expressions#show', via: [:get, :post]
	match 'expressions/:wfid/:expid/update', :to => 'expressions#update', via: [:put]

	#rails2 map.connect('expressions/:wfid/:expid/tree',	:controller => 'expressions',	:action => 'update_tree',:conditions => { :method => :put })
	match 'expressions/:wfid/:expid/tree', :to => 'expressions#update_tree', via: [:get, :post]

	match 'expressions/:wfid/:expid/destroy', :to => 'expressions#destroy', via: [:delete]

	#rails2 map.resources :forums, :member=> {:edit_lifecycle => :get}
	resources :forums do
        member do
            get :edit_lifecycle
        end
        collection do
            get :export
        end
    end
    #rails2 map.connect(    'forums/:id/update_lifecycle',  :controller => 'forums',    :action => 'update_lifecycle')
    match 'forums/update_lifecycle', :to => 'forums#update_lifecycle', via: [:get, :post]
    match 'forums/index_execute', :to => 'forums#index_execute', via: [:get, :post]

    #rails2 map.connect(    'forums/:id/update_type',   :controller => 'forums',    :action => 'update_type')
    match 'forums/update_type', :to => 'forums#update_type', via: [:get, :post]

	#rails2 map.resources :forum_items
	resources :forum_items , :only => [:create, :edit, :update] do
		member do
			get :destroy
		end
		collection do
			get :new
			get :export
		end
	end
	match 	'forum_items/index', :to => 'forum_items#index', via: [:get, :post]

	#rails2 map.resources :groups, :member=> {:new_dup => :get}
	resources :groups do
		member do
			get :new_dup
		end
		collection do
			get :export
		end
	end
	#rails2 map.connect(	'groups/index_execute',	:controller => 'groups',	:action => 'index_execute')
	match 	'groups/index_execute', :to => 'groups#index_execute', via: [:get, :post]

	#rails2 map.connect(	'groups/:id/select_view',	:controller => 'groups',	:action => 'select_view')
	match 'groups/:id/select_view', :to => 'groups#select_view', via: [:patch]

	#rails2 map.resources :group_definitions
	resources :group_definitions

	#rails2 map.resources :help, :only => [:index]
	resources :help , :only => [:index]

	#rails2 map.resources :history
	resources :history

	#rails2 map.connect(	'info/list_objects/:plmtype.:format',	:controller => 'info',	:action => 'list_objects')
	match 'info/list_objects/:plmtype.:format', :to => 'info#list_objects', via: [:get, :post]

	#rails2 map.connect(	'info/object_links/:plmtype/:id.:format',	:controller => 'info',	:action => 'object_links')
	match 	'info/object_links/:plmtype/:id.:format', :to => 'info#object_links', via: [:get, :post]

	#rails2 map.resources :links, :collection => { :reset => :get, :empty_clipboard => :get}
	resources :links do
		collection do
			get :reset
			get :empty_clipboard
		end
		collection do
			get :export
		end
	end
	#rails2 map.connect(	'links/:id/edit_in_tree',	:controller => 'links',	:action => 'edit_in_tree',	:conditions => { :method => :get })
	match 	'links/:id/edit_in_tree', :to => 'links#edit_in_tree', via: [:get, :post]

	#rails2 map.connect(	'links/:id/update_in_tree',	:controller => 'links',	:action => 'update_in_tree')
	match 'links/:id/update_in_tree', :to => 'links#update_in_tree', via: [:patch]

	#rails2 map.connect(	'links/:id/remove_link',	:controller => 'links',	:action => 'remove_link')
	match 'links/:id/remove_link', :to => 'links#remove_link', via: [:get, :post]

	#rails2 map.connect(	'links/:id/add_clipboard',	:controller => 'links',	:action => 'add_clipboard',	:conditions => { :method => :get })
	match 'links/:id/add_clipboard', :to => 'links#add_clipboard', via: [:get, :post], as: :add_clipboard_link

	#rails2 map.resources :notifications, :member => { :notify => :get }
	resources :notifications do
		member do
			get :notify
		end
		collection do
			get :export
		end
	end
	#rails2 map.resources :parts, :has_many => :documents, :collection => { :empty_clipboard => :get}, :member=> {:edit_lifecycle => :get,:new_dup => :get}
	resources :parts do
		member do
			get :edit_lifecycle
			get :new_dup
			get :add_clipboard
		end
		collection do
			get :empty_clipboard
			get :export
		end
	end
	#rails2 map.connect(	'parts/index_execute',	:controller => 'parts',	:action => 'index_execute')
	match 'parts/action', :to => 'parts#index_execute', via: [:get, :post]

	#rails2 map.connect(	'parts/:id/add_clipboard',	:controller => 'parts',	:action => 'add_clipboard',	:conditions => { :method => :get })
	#match 'parts/:id/add_clipboard', :to => 'parts#add_clipboard', :via=> [:get], :as => :add_clipboard_part , :defaults => { :format => 'js' }
	#match 'parts/:id/add_clipboard', :to => 'parts#add_clipboard', :via=> [:get, :post], :as => :add_clipboard_part

	#rails2 map.connect(	'parts/:id/promote',	:controller => 'parts',	:action => 'promote',	:conditions => { :method => :get })
	match 'parts/:id/promote', :to => 'parts#promote', via: [:get, :post]

	#rails2 map.connect(	'parts/:id/demote',	:controller => 'parts',	:action => 'demote',	:conditions => { :method => :get })
	match 'parts/:id/demote', :to => 'parts#demote', via: [:get, :post]

	#rails2 map.connect(	'parts/:id/revise',	:controller => 'parts',	:action => 'revise',	:conditions => { :method => :get })
	match 'parts/:id/revise', :to => 'parts#revise', via: [:get, :post]

	#rails2 map.connect(	'parts/:id/add_objects',	:controller => 'parts',	:action => 'add_objects')
	match 'parts/:id/add_objects', :to => 'parts#add_objects', via: [:patch]

	#rails2 map.connect(	'parts/:id/add_link_objects',	:controller => 'parts',	:action => 'add_link_objects')
	match 	'parts/:id/add_link_objects', :to => 'parts#add_link_objects', via:  [:patch]

	#rails2 map.connect(	'parts/:id/remove_link',	:controller => 'parts',	:action => 'remove_link',	:conditions => { :method => :get })
	match 'parts/:id/remove_link', :to => 'parts#remove_link', via: [:get, :post]

	#rails2 map.connect(	'parts/:id/new_forum',	:controller => 'parts',	:action => 'new_forum')
	match 'parts/:id/new_forum', :to => 'parts#new_forum', via: [:patch]

	#rails2 map.connect(	'parts/:id/add_forum',	:controller => 'parts',	:action => 'add_forum')
	match	'parts/:id/add_forum', :to => 'parts#add_forum', via: [:get, :post]

	#rails2 map.connect(	'parts/:id/promote',	:controller => 'parts',	:action => 'promote',	:conditions => { :method => :get })
	match	'parts/:id/promote', :to => 'parts#promote', via: [:get, :post]

	#rails2 map.connect(	'parts/:id/demote',	:controller => 'parts',	:action => 'demote',	:conditions => { :method => :get })
	match 'parts/:id/demote', :to => 'parts#demote', via: [:get, :post]

	#rails2 map.connect(	'parts/:id/select_view',	:controller => 'parts',	:action => 'select_view')
	match 	'parts/:id/select_view', :to => 'parts#select_view', via: [ :patch]

	#rails2 map.connect(	'parts/:id/new_datafile',	:controller => 'parts',	:action => 'new_datafile')
	match 	'parts/:id/new_datafile', :to => 'parts#new_datafile', via: [:get, :post]

	#rails2 map.connect(	'parts/:id/add_datafile',	:controller => 'parts',	:action => 'add_datafile')
	match 'parts/:id/add_datafile', :to => 'parts#add_datafile', via: [:get, :post]

	#rails2 map.connect(	'parts/:id/update_lifecycle',	:controller => 'parts',	:action => 'update_lifecycle')
	match 'parts/:id/update_lifecycle', :to => 'parts#update_lifecycle', via: [:get, :post]

	#rails2 map.connect(	'parts/:id/show_design',	:controller => 'parts',	:action => 'show_design')
	match 	'parts/:id/show_design', :to => 'parts#show_design', via: [:get, :post]

	#rails2 map.connect(	'parts/:id/update_type',	:controller => 'parts',	:action => 'update_type')
	match 'parts/:id/update_type', :to => 'parts#update_type', via: [:get, :post]

	#rails2 map.resources :processes
	resources :processes

	#rails2 map.connect(	'processes/:id/tree.js',	:controller => 'processes',	:action => 'tree')
	match 'processes/:id/tree.js', :to => 'processes#tree', via: [:get, :post]

	#rails2 map.resources :projects, :has_many => :documents, :collection => { :empty_clipboard => :get}, :member=> {:edit_lifecycle => :get,:new_dup => :get}
	resources :projects do
		member do
			get :edit_lifecycle
			get :new_dup
		end
		collection do
			get :empty_clipboard
			get :export
		end
	end
	#rails2 map.connect(	'projects/index_execute',	:controller => 'projects',	:action => 'index_execute')
	match 'projects/index_execute', :to => 'projects#index_execute', via: [:get, :post]

	#rails2 map.connect(	'projects/:id/add_clipboard',	:controller => 'projects',	:action => 'add_clipboard',	:conditions => { :method => :get })
	match 	'projects/:id/add_clipboard', :to => 'projects#add_clipboard', via: [:get, :post], as: :add_clipboard_project

	#rails2 map.connect(	'projects/:id/add_objects',	:controller => 'projects',	:action => 'add_objects')
	match 'projects/:id/add_objects', :to => 'projects#add_objects', via: [:patch]

	#rails2 map.connect(	'projects/:id/add_link_objects',	:controller => 'projects',	:action => 'add_link_objects')
	match 	'projects/:id/add_link_objects', :to => 'projects#add_link_objects', via:  [:patch]

	#rails2 map.connect(	'projects/:id/remove_link',	:controller => 'projects',	:action => 'remove_link',	:conditions => { :method => :get })
	match 'projects/:id/remove_link', :to => 'projects#remove_link', via: [:get, :post]

	#rails2 map.connect(	'projects/:id/new_forum',	:controller => 'projects',	:action => 'new_forum')
	match 	'projects/:id/new_forum', :to => 'projects#new_forum', via: [:patch]

	#rails2 map.connect(	'projects/:id/add_forum',	:controller => 'projects',	:action => 'add_forum')
	match 'projects/:id/add_forum', :to => 'projects#add_forum', via: [:get, :post]

	#rails2 map.connect(	'projects/:id/promote',	:controller => 'projects',	:action => 'promote',	:conditions => { :method => :get })
	match 'projects/:id/promote',	 :to => 'projects#promote', via: [:get, :post]

	#rails2 map.connect(	'projects/:id/demote',	:controller => 'projects',	:action => 'demote',	:conditions => { :method => :get })
	match 'projects/:id/demote', :to => 'projects#demote', via: [:get, :post]

	#rails2 map.connect(	'projects/:id/select_view',	:controller => 'projects',	:action => 'select_view')
	match 'projects/:id/select_view', :to => 'projects#select_view', via:[:patch]

	#rails2 map.connect(	'projects/:id/new_datafile',	:controller => 'projects',	:action => 'new_datafile')
	match 'projects/:id/new_datafile', :to => 'projects#new_datafile', via: [:get, :post]

	#rails2 map.connect(	'projects/:id/add_datafile',	:controller => 'projects',	:action => 'add_datafile')
	match 'projects/:id/add_datafile', :to => 'projects#add_datafile', via: [:get, :post]

	#rails2 map.connect(	'projects/:id/update_lifecycle',	:controller => 'projects',	:action => 'update_lifecycle')
	match 	'projects/:id/update_lifecycle', :to => 'projects#update_lifecycle', via: [:get, :post]

	#rails2 map.connect(	'projects/:id/show_design',	:controller => 'projects',	:action => 'show_design')
	match 	'projects/:id/show_design', :to => 'projects#show_design', via: [:get, :post]

	#rails2 map.connect(	'projects/:id/update_type',	:controller => 'projects',	:action => 'update_type')
	match	'projects/:id/update_type', :to => 'projects#update_type', via: [:get, :post]

	#rails2 map.resources :relations, :member=> {:new_dup => :get}
	resources :relations do
		member do
			get :new_dup
		end
		collection do
			get :export
		end
	end
	#rails2 map.connect(	'relations/index_execute',	:controller => 'relations',	:action => 'index_execute')
	match 'relations/index_execute', :to => 'relations#index_execute', via: [:get, :post]

	#rails2 map.connect(	'relations/update_father',	:controller => 'relations',	:action => 'update_father')
	match 'relations/update_father', :to => 'relations#update_father', via: [:get, :post]

	#rails2 map.connect(	'relations/update_child',	:controller => 'relations',	:action => 'update_child')
	match 'relations/update_child', :to => 'relations#update_child', via: [:get, :post]

	#rails2 map.connect(	'relations/:id/update_type',	:controller => 'relations',	:action => 'update_type')
	match 'relations/update_type', :to => 'relations#update_type', via: [:get, :post]

	#rails2 map.resources :questions
	resources :questions
	match 'questions/index_execute', :to => 'questions#index_execute', via: [:get, :post]

	#rails2 map.resources :roles, :member=> {:new_dup => :get}
	resources :roles do
		member do
			get :new_dup
		end
		collection do
			get :export
		end
	end
	#rails2 map.connect(	'roles/index_execute',	:controller => 'roles',	:action => 'index_execute')
	match 'roles/index_execute', :to => 'roles#index_execute', via: [:get, :post]

	#rails2 map.connect(	'roles/:id/select_view',	:controller => 'roles',	:action => 'select_view')
	match 'roles/:id/select_view', :to => 'roles#select_view', via:[:patch]

	#rails2 map.resources :sequences, :member=> {:new_dup => :get}
	resources :sequences do
		member do
			get :new_dup
		end
		collection do
			get :export
		end
	end
	#rails2 map.connect(	'sequences/index_execute',	:controller => 'sequences',	:action => 'index_execute')
	match 'sequences/index_execute', :to => 'sequences#index_execute', via: [:get, :post]

	#rails2 map.resource :sessions, :only => [:new, :create , :destroy]
	resources :sessions , :only => [:new, :create , :destroy] do
		collection do
			get :new_account
			post :create_account
		end
	end
	match 'sessions/', :to => 'sessions#destroy', via: [:delete]

	#rails2 TODO  map.new_account 'sessions/new_account', controller: 'sessions', action: 'new_account', conditions: { method: :get }
	#rails2 TODO  map.create_account 'sessions/create_account', controller: 'sessions', action: 'create_account', conditions: { method: :post }

	#rails2 map.connect(	'sessions/login',	:controller => 'sessions',	:action => 'login')
	match 'sessions/login', :to => 'sessions#login', via: [:get, :post]

	#rails2 map.connect(	'sessions/:id/activate',	:controller => 'sessions',	:action => 'activate')
	match 'sessions/:id/activate', :to => 'sessions#activate', via: [:get, :post]

	#rails2 map.resources :statusobjects, :member=> {:new_dup => :get}
	resources :statusobjects do
		member do
			get :new_dup
		end
		collection do
			get :export
		end
	end
	#rails2 map.connect(	'statusobjects/index_execute',	:controller => 'statusobjects',	:action => 'index_execute')
	match 'statusobjects/index_execute', :to => 'statusobjects#index_execute', via: [:get, :post]

	#rails2 map.connect(	'statusobjects/:id/update_type',	:controller => 'statusobjects',	:action => 'update_type')
	match	'statusobjects/:id/update_type', :to => 'statusobjects#update_type', via: [:get, :post]

	#rails2 map.resources :subscriptions, :member=> {:new_dup => :get}
	resources :subscriptions do
		member do
			get :new_dup
		end
		collection do
			get :export
		end
	end
	#rails2 map.connect(	'subscriptions/index_execute',	:controller => 'subscriptions',	:action => 'index_execute')
	match 'subscriptions/index_execute', :to => 'subscriptions#index_execute', via: [:get, :post]

	#rails2 map.resources :typesobjects, :member=> {:new_dup => :get}
	resources :typesobjects do
		member do
			get :new_dup
		end
		collection do
			get :export
		end
	end
	#rails2 map.connect(	'typesobjects/index_execute' ,	:controller => 'typesobjects',	:action => 'index_execute')
	match 'typesobjects/index_execute', :to => 'typesobjects#index_execute', via: [:get, :post]

	#rails2 map.connect(	'typesobjects/:id/update_forobject' ,	:controller => 'typesobjects',	:action => 'update_forobject')
	match 'typesobjects/:id/update_forobject', :to => 'typesobjects#update_forobject', via: [:get, :post]

	#rails2 map.resources :users, :collection => { :empty_clipboard => :get }, :member=> {:new_dup => :get}
	resources :users do
		member do
			get :new_dup
		end
		collection do
			get :empty_clipboard
			get :export
		end
	end
	#rails2 map.connect(	'users/index_execute',	:controller => 'users',	:action => 'index_execute')
	match 'users/index_execute',	 :to => 'users#index_execute', via: [:get, :post]

	#rails2 map.connect(	'users/:id/activate',	:controller => 'users',	:action => 'activate')
	match 'users/:id/activate', :to => 'users#activate', via: [:get, :post]

	#rails2 map.connect(	'users/:id/add_clipboard',	:controller => 'users',	:action => 'add_clipboard',	:conditions => { :method => :get })
	match 'users/:id/add_clipboard', :to => 'users#add_clipboard', via: [:get, :post], as: :add_clipboard_user

	#rails2 map.connect(	'users/browse',	:controller => 'users',	:action => 'browse')
	match 'users/browse', :to => 'users#browse', via: [:get, :post]

	#rails2 map.connect(	'users/:id/reset_passwd',	:controller => 'users',	:action => 'reset_passwd')
	match 'users/:id/reset_passwd', :to => 'users#reset_passwd', via: [:get, :post]

	#rails2 map.connect(	'users/:id/account_edit',	:controller => 'users',	:action => 'account_edit')
	match 'users/:id/account_edit', :to => 'users#account_edit', via: [:get, :post]

	#rails2 map.connect(	'users/:id/account_update',	:controller => 'users',	:action => 'account_update')
	match 	'users/:id/account_update', :to => 'users#account_update', via: [:patch, :get, :post]

	#rails2 map.connect(	'users/:id/account_edit_passwd',	:controller => 'users',	:action => 'account_edit_passwd')
	match	'users/:id/account_edit_passwd', :to => 'users#account_edit_passwd', via: [ :get, :post]

	#rails2 map.connect(	'users/:id/update_type',	:controller => 'users',	:action => 'update_type')
	match 'users/:id/update_type', :to => 'users#update_type', via: [:get, :post]

	#rails2 map.resources :user_groups
	resources :user_groups

	#
	resources :ui_columns do
	member do
			get :new_dup
		end
		collection do
			get :export
		end
	end
	match 'ui_columns/index_execute', :to => 'ui_columns#index_execute', via: [:get, :post]

		#
  	resources :ui_tables do
	member do
			get :new_dup
		end
		collection do
			get :export
		end

	end
	match 'ui_tables/index_execute', :to => 'ui_tables#index_execute', via: [:get, :post]

	#rails2 map.resources :views, :member=> {:new_dup => :get}
	resources :views do
		member do
			get :new_dup
		end
		collection do
			get :export
		end
	end
	#rails2 map.connect(	'views/index_execute',	:controller => 'views',	:action => 'index_execute')
	match 'views/index_execute', :to => 'views#index_execute', via: [:get, :post]

	#rails2 map.resources :volumes, :member=> {:new_dup => :get}
	resources :volumes do
		member do
			get :new_dup
		end
		collection do
			get :export
		end
	end
	#rails2 map.connect(	'volumes/index_execute',	:controller => 'volumes',	:action => 'index_execute')
	match	'volumes/index_execute', :to => 'volumes#index_execute', via: [:get, :post]

	#rails2 map.wfid_resources :errors
	resources :errors

	#rails2 map.wfid_resources :workitems
	resources :workitems
	match 'workitems/:wfid/show', :to => 'workitems#show', via: [:get, :post]

	#rails2 map.wfid_resources :expressions
	resources :expressions
end