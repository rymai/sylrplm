# This file is auto-generated from the current state of the database. Instead of editing this file,
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 0) do

	create_table "accesses", :force => true do |t|
		t.string   "roles"
		t.string   "controller"
		t.string   "action"
		t.datetime "created_at"
		t.datetime "updated_at"
		t.string   "domain"
	end

	add_index "accesses", ["action"], :name => "index_accesses_on_action"
	add_index "accesses", ["controller"], :name => "index_accesses_on_controller"
	add_index "accesses", ["roles"], :name => "index_accesses_on_roles"

	create_table "ar_workitems", :force => true do |t|
		t.string   "fei"
		t.string   "wfid"
		t.string   "expid"
		t.string   "wfname"
		t.string   "wfrevision"
		t.string   "participant_name"
		t.string   "store_name"
		t.text     "wi_fields"
		t.string   "activity"
		t.text     "keywords"
		t.datetime "dispatch_time"
		t.datetime "last_modified"
	end

	add_index "ar_workitems", ["expid"], :name => "index_ar_workitems_on_expid"
	add_index "ar_workitems", ["fei"], :name => "index_ar_workitems_on_fei", :unique => true
	add_index "ar_workitems", ["participant_name"], :name => "index_ar_workitems_on_participant_name"
	add_index "ar_workitems", ["store_name"], :name => "index_ar_workitems_on_store_name"
	add_index "ar_workitems", ["wfid"], :name => "index_ar_workitems_on_wfid"
	add_index "ar_workitems", ["wfname"], :name => "index_ar_workitems_on_wfname"
	add_index "ar_workitems", ["wfrevision"], :name => "index_ar_workitems_on_wfrevision"

	create_table "checks", :force => true do |t|
		t.string   "checkobject_plmtype"
		t.integer  "checkobject_id"
		t.integer  "status"
		t.boolean  "automatic"
		t.string   "out_reason"
		t.integer  "out_user_id"
		t.integer  "out_group_id"
		t.date     "out_date"
		t.string   "in_reason"
		t.integer  "in_user_id"
		t.integer  "in_group_id"
		t.date     "in_date"
		t.integer  "projowner_id"
		t.datetime "created_at"
		t.datetime "updated_at"
	end

	add_index "checks", ["in_group_id"], :name => "index_checks_on_in_group_id"
	add_index "checks", ["in_user_id"], :name => "index_checks_on_in_user_id"
	add_index "checks", ["checkobject_plmtype", "checkobject_id"], :name => "index_checks_on_object_and_object_id"
	add_index "checks", ["out_group_id"], :name => "index_checks_on_out_group_id"
	add_index "checks", ["out_user_id"], :name => "index_checks_on_out_user_id"
	add_index "checks", ["projowner_id"], :name => "index_checks_on_projowner_id"

	create_table "customers", :force => true do |t|
		t.integer  "owner_id"
		t.integer  "typesobject_id"
		t.integer  "statusobject_id"
		t.integer  "next_status_id"
		t.integer  "previous_status_id"
		t.string   "ident"
		t.string   "revision"
		t.string   "designation"
		t.text     "description"
		t.date     "date"
		t.datetime "created_at"
		t.datetime "updated_at"
		t.integer  "group_id"
		t.integer  "projowner_id"
		t.string   "domain"
		t.string   "type_values"
	end

	add_index "customers", ["group_id"], :name => "index_customers_on_group_id"
	add_index "customers", ["ident"], :name => "index_customers_on_ident"
	add_index "customers", ["owner_id"], :name => "index_customers_on_owner_id"
	add_index "customers", ["projowner_id"], :name => "index_customers_on_projowner_id"
	add_index "customers", ["statusobject_id"], :name => "index_customers_on_statusobject_id"
	add_index "customers", ["typesobject_id"], :name => "index_customers_on_typesobject_id"

	create_table "datafiles", :force => true do |t|
		t.integer  "owner_id"
		t.integer  "typesobject_id"
		t.integer  "customer_id"
		t.integer  "document_id"
		t.integer  "part_id"
		t.integer  "project_id"
		t.integer  "volume_id"
		t.integer  "revision"
		t.string   "ident"
		t.string   "filename"
		t.string   "content_type"
		t.datetime "created_at"
		t.datetime "updated_at"
		t.integer  "group_id"
		t.integer  "projowner_id"
		t.string   "domain"
		t.string   "type_values"
	end

	add_index "datafiles", ["document_id"], :name => "index_datafiles_on_document_id"
	add_index "datafiles", ["group_id"], :name => "index_datafiles_on_group_id"
	add_index "datafiles", ["projowner_id"], :name => "index_datafiles_on_projowner_id"
	add_index "datafiles", ["typesobject_id"], :name => "index_datafiles_on_typesobject_id"
	add_index "datafiles", ["volume_id"], :name => "index_datafiles_on_volume_id"

	create_table "definitions", :force => true do |t|
		t.string   "name"
		t.string   "description"
		t.string   "uri"
		t.text     "launch_fields"
		t.datetime "created_at"
		t.datetime "updated_at"
		t.string   "domain"
	end

	add_index "definitions", ["name"], :name => "index_definitions_on_name", :unique => true

	create_table "definitions_roles", :id => false, :force => true do |t|
		t.integer  "definition_id", :null => false
		t.integer  "role_id",      :null => false
		t.datetime "created_at"
		t.datetime "updated_at"
		t.string   "domain"
	end

	add_index "definitions_roles", ["definition_id", "role_id" ], :name => "index_definitions_roles_on_role_id_and_definition_id", :unique => true

	create_table "documents", :force => true do |t|
		t.integer  "owner_id"
		t.integer  "typesobject_id"
		t.integer  "statusobject_id"
		t.integer  "next_status_id"
		t.integer  "previous_status_id"
		t.string   "ident"
		t.string   "revision"
		t.string   "designation"
		t.text     "description"
		t.date     "date"
		t.datetime "created_at"
		t.datetime "updated_at"
		t.integer  "group_id"
		t.integer  "projowner_id"
		t.string   "domain"
		t.string   "type_values"
	end

	add_index "documents", ["group_id"], :name => "index_documents_on_group_id"
	add_index "documents", ["ident"], :name => "index_documents_on_ident"
	add_index "documents", ["owner_id"], :name => "index_documents_on_owner_id"
	add_index "documents", ["projowner_id"], :name => "index_documents_on_projowner_id"
	add_index "documents", ["statusobject_id"], :name => "index_documents_on_statusobject_id"
	add_index "documents", ["typesobject_id"], :name => "index_documents_on_typesobject_id"

	create_table "expressions", :force => true do |t|
		t.string "fei",       :null => false
		t.string "wfid",      :null => false
		t.string "expid",     :null => false
		t.string "exp_class", :null => false
		t.string   "svalue",    :null => false, :limit => 1024 * 1024
		t.text   "text",      :null => false
	end

	add_index "expressions", ["exp_class"], :name => "index_expressions_on_exp_class"
	add_index "expressions", ["expid"], :name => "index_expressions_on_expid"
	add_index "expressions", ["fei"], :name => "index_expressions_on_fei"
	add_index "expressions", ["wfid"], :name => "index_expressions_on_wfid"

	create_table "forum_items", :force => true do |t|
		t.integer  "forum_id"
		t.integer  "parent_id"
		t.integer  "owner_id"
		t.text     "message"
		t.datetime "created_at"
		t.datetime "updated_at"
		t.integer  "group_id"
		t.integer  "projowner_id"
		t.string   "domain"
	end

	add_index "forum_items", ["forum_id"], :name => "index_forum_items_on_forum_id"
	add_index "forum_items", ["group_id"], :name => "index_forum_items_on_group_id"
	add_index "forum_items", ["owner_id"], :name => "index_forum_items_on_owner_id"
	add_index "forum_items", ["parent_id"], :name => "index_forum_items_on_parent_id"
	add_index "forum_items", ["projowner_id"], :name => "index_forum_items_on_projowner_id"

	create_table "forums", :force => true do |t|
		t.integer  "owner_id"
		t.integer  "typesobject_id"
		t.integer  "statusobject_id"
		t.integer  "next_status_id"
		t.integer  "previous_status_id"
		t.string   "subject"
		t.text     "description"
		t.datetime "created_at"
		t.datetime "updated_at"
		t.integer  "group_id"
		t.integer  "projowner_id"
		t.string   "domain"
		t.string   "type_values"
	end

	add_index "forums", ["group_id"], :name => "index_forums_on_group_id"
	add_index "forums", ["owner_id"], :name => "index_forums_on_owner_id"
	add_index "forums", ["projowner_id"], :name => "index_forums_on_projowner_id"
	add_index "forums", ["statusobject_id"], :name => "index_forums_on_statusobject_id"
	add_index "forums", ["typesobject_id"], :name => "index_forums_on_typesobject_id"

	create_table "groups", :force => true do |t|
		t.string   "name"
		t.datetime "created_at"
		t.datetime "updated_at"
		t.integer  "father_id"
		t.string   "domain"
	end

	add_index "groups", ["name"], :name => "index_groups_on_name", :unique => true

	create_table "groups_users", :id => false, :force => true do |t|
		t.integer "group_id", :null => false
		t.integer "user_id",  :null => false
		t.string  "domain"
	end

	add_index "groups_users", ["user_id", "group_id"], :name => "index_groups_users_on_user_id_and_group_id", :unique => true

	create_table "history_entry", :force => true do |t|
		t.string   "source",      :null => false
		t.string   "event",       :null => false
		t.string   "wfid"
		t.string   "wfname"
		t.string   "wfrevision"
		t.string   "fei"
		t.string   "participant"
		t.string   "message"
		t.text     "tree"
		t.datetime "created_at"
	end

	add_index "history_entry", ["created_at"], :name => "index_history_entry_on_created_at"
	add_index "history_entry", ["event"], :name => "index_history_entry_on_event"
	add_index "history_entry", ["participant"], :name => "index_history_entry_on_participant"
	add_index "history_entry", ["source"], :name => "index_history_entry_on_source"
	add_index "history_entry", ["wfid"], :name => "index_history_entry_on_wfid"
	add_index "history_entry", ["wfname"], :name => "index_history_entry_on_wfname"
	add_index "history_entry", ["wfrevision"], :name => "index_history_entry_on_wfrevision"

	create_table "links", :force => true do |t|
		t.string   "father_plmtype", :null => false
		t.string   "child_plmtype",  :null => false
		t.integer  "father_id",      :null => false
		t.integer  "child_id",       :null => false
		t.datetime "created_at",     :null => false
		t.datetime "updated_at",     :null => false
		t.integer  "father_typesobject_id", :null => false
		t.integer  "child_typesobject_id",  :null => false
		t.integer  "relation_id",    :null => false
		t.string   "values"
		t.integer  "owner_id"
		t.integer  "group_id"
		t.integer  "projowner_id"
		t.string   "domain"
	end

	add_index "links", ["child_plmtype"], :name => "index_links_on_child_plmtype"
	add_index "links", ["child_typesobject_id"], :name => "index_links_on_child_typesobject_id"
	add_index "links", ["father_plmtype"], :name => "index_links_on_father_plmtype"
	add_index "links", ["father_typesobject_id"], :name => "index_links_on_father_typesobject_id"
	add_index "links", ["group_id"], :name => "index_links_on_group_id"
	add_index "links", ["owner_id"], :name => "index_links_on_owner_id"
	add_index "links", ["projowner_id"], :name => "index_links_on_projowner_id"
	add_index "links", ["relation_id"], :name => "index_links_on_relation_id"

	create_table "notifications", :force => true do |t|
		t.string   "forobject_type"
		t.integer  "forobject_id"
		t.integer  "responsible_id"
		t.text     "event_type"
		t.date     "event_date"
		t.date     "notify_date"
		t.string   "notify_users"
		t.datetime "created_at"
		t.datetime "updated_at"
	end

	add_index "notifications", ["forobject_type", "forobject_id"], :name => "index_notifications_on_object_type_and_object_id"
	add_index "notifications", ["responsible_id"], :name => "index_notifications_on_responsible_id"

	create_table "parts", :force => true do |t|
		t.integer  "owner_id"
		t.integer  "typesobject_id"
		t.integer  "statusobject_id"
		t.integer  "next_status_id"
		t.integer  "previous_status_id"
		t.string   "ident"
		t.string   "revision"
		t.string   "designation"
		t.text     "description"
		t.date     "date"
		t.datetime "created_at"
		t.datetime "updated_at"
		t.integer  "group_id"
		t.integer  "projowner_id"
		t.string   "domain"
		t.string   "type_values"
	end

	add_index "parts", ["group_id"], :name => "index_parts_on_group_id"
	add_index "parts", ["ident"], :name => "index_parts_on_ident"
	add_index "parts", ["owner_id"], :name => "index_parts_on_owner_id"
	add_index "parts", ["projowner_id"], :name => "index_parts_on_projowner_id"
	add_index "parts", ["statusobject_id"], :name => "index_parts_on_statusobject_id"
	add_index "parts", ["typesobject_id"], :name => "index_parts_on_typesobject_id"

	create_table "process_errors", :force => true do |t|
		t.string   "wfid",       :null => false
		t.string   "expid",      :null => false
		t.text     "svalue",     :null => false
		t.datetime "created_at"
	end

	add_index "process_errors", ["created_at"], :name => "index_process_errors_on_created_at"
	add_index "process_errors", ["expid"], :name => "index_process_errors_on_expid"
	add_index "process_errors", ["wfid"], :name => "index_process_errors_on_wfid"

	create_table "projects", :force => true do |t|
		t.integer  "owner_id"
		t.integer  "typesobject_id"
		t.integer  "statusobject_id"
		t.integer  "next_status_id"
		t.integer  "previous_status_id"
		t.string   "ident"
		t.string   "revision"
		t.string   "designation"
		t.text     "description"
		t.date     "date"
		t.datetime "created_at"
		t.datetime "updated_at"
		t.integer  "group_id"
		t.integer  "typeaccess_id"
		t.string   "domain"
		t.string   "type_values"
	end

	add_index "projects", ["group_id"], :name => "index_projects_on_group_id"
	add_index "projects", ["ident"], :name => "index_projects_on_ident"
	add_index "projects", ["owner_id"], :name => "index_projects_on_owner_id"
	add_index "projects", ["statusobject_id"], :name => "index_projects_on_statusobject_id"
	add_index "projects", ["typeaccess_id"], :name => "index_projects_on_typeaccess_id"
	add_index "projects", ["typesobject_id"], :name => "index_projects_on_typesobject_id"

	create_table "projects_users", :id => false, :force => true do |t|
		t.integer  "project_id", :null => false
		t.integer  "user_id",    :null => false
		t.datetime "created_at"
		t.datetime "updated_at"
		t.string   "domain"
	end

	add_index "projects_users", ["project_id", "user_id"], :name => "index_projects_users_on_project_id_and_user_id", :unique => true

	create_table "questions", :force => true do |t|
		t.string   "question"
		t.string   "answer"
		t.integer  "position"
		t.datetime "created_at"
		t.datetime "updated_at"
		t.integer  "asker_id"
		t.integer  "responder_id"
		t.string   "domain"
	end

	add_index "questions", ["asker_id"], :name => "index_questions_on_asker_id"
	add_index "questions", ["responder_id"], :name => "index_questions_on_responder_id"

	create_table "relations", :force => true do |t|
		t.string   "name"
		t.integer  "typesobject_id"
		t.string   "father_plmtype"
		t.string   "child_plmtype"
		t.integer  "father_typesobject_id"
		t.integer  "child_typesobject_id"
		t.integer  "cardin_occur_min"
		t.integer  "cardin_occur_max"
		t.integer  "cardin_use_min"
		t.integer  "cardin_use_max"
		t.datetime "created_at"
		t.datetime "updated_at"
		t.string   "domain"
		t.string   "type_values"
	end

	add_index "relations", ["child_plmtype", "child_typesobject_id"], :name => "index_relations_on_child_plmtype_and_child_typesobject_id"
	add_index "relations", ["father_plmtype", "father_typesobject_id"], :name => "index_relations_on_father_plmtype_and_father_typesobject_id"
	add_index "relations", ["name"], :name => "index_relations_on_name"
	add_index "relations", ["typesobject_id"], :name => "index_relations_on_typesobject_id"

	create_table "relations_views", :id => false, :force => true do |t|
		t.integer  "relation_id", :null => false
		t.integer  "view_id",     :null => false
		t.datetime "created_at"
		t.datetime "updated_at"
		t.string   "domain"
	end

	add_index "relations_views", ["relation_id", "view_id"], :name => "index_relations_views_on_relation_id_and_view_id", :unique => true

	create_table "roles", :force => true do |t|
		t.string   "title"
		t.text     "description"
		t.datetime "created_at"
		t.datetime "updated_at"
		t.integer  "father_id"
		t.string   "domain"
	end

	add_index "roles", ["father_id"], :name => "index_roles_on_father_id"

	create_table "roles_users", :id => false, :force => true do |t|
		t.integer  "role_id",    :null => false
		t.integer  "user_id",    :null => false
		t.datetime "created_at"
		t.datetime "updated_at"
		t.string   "domain"
	end

	add_index "roles_users", ["role_id", "user_id"], :name => "index_roles_users_on_role_id_and_user_id", :unique => true

	create_table "sequences", :force => true do |t|
		t.string   "value"
		t.string   "min"
		t.string   "max"
		t.string   "utility"
		t.boolean  "modify"
		t.boolean  "sequence"
		t.datetime "created_at"
		t.datetime "updated_at"
		t.string   "domain"
	end

	add_index "sequences", ["utility"], :name => "index_sequences_on_utility", :unique => true

	create_table "sessions", :force => true do |t|
		t.string   "session_id", :null => false
		t.text     "data"
		t.datetime "created_at"
		t.datetime "updated_at"
	end

	add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
	add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

	create_table "statusobjects", :force => true do |t|
		t.string   "forobject"
		t.integer  "typesobject_id"
		t.string   "name"
		t.text     "description"
		t.integer  "rank"
		t.integer  "promote_id"
		t.integer  "demote_id"
		t.integer  "revise_id"
		t.datetime "created_at"
		t.datetime "updated_at"
		t.string   "domain"
	end

	add_index "statusobjects", ["forobject", "rank", "name"], :name => "index_statusobjects_on_object_and_rank_and_name", :unique => true

	create_table "statusobjects_nexts", :id => false, :force => true do |t|
		t.integer  "statusobject_id",    :null => false
		t.integer  "other_statusobject_id",    :null => false
		t.datetime "created_at"
		t.datetime "updated_at"
		t.string   "domain"
	end
	add_index "statusobjects_nexts", ["statusobject_id", "other_statusobject_id"], :name => "index_statusobjects_nexts_on_statusobjects_id_and_other_statusobject_id", :unique => true

	create_table "statusobjects_previous", :id => false, :force => true do |t|
		t.integer  "statusobject_id",    :null => false
		t.integer  "other_statusobject_id",    :null => false
		t.datetime "created_at"
		t.datetime "updated_at"
		t.string   "domain"
	end
	add_index "statusobjects_previous", ["statusobject_id", "other_statusobject_id"], :name => "index_statusobjects_previous_on_statusobject_id_and_other_statusobject_id", :unique => true

	create_table "subscriptions" , :force => true do |t|
		t.string   "name"
		t.string "designation"
		t.text  "description"
		t.integer "owner_id"
		t.boolean "oncreate"
		t.boolean "onupdate"
		t.boolean "ondestroy"
		t.datetime "created_at"
		t.datetime "updated_at"
		t.string   "domain"
	end

	add_index "subscriptions", ["name"], :name => "index_subscriptions_on_name", :unique => true

	create_table "subscriptions_typesobjects", :id => false, :force => true do |t|
		t.integer  "subscription_id",    :null => false
		t.integer  "typesobject_id",    :null => false
		t.datetime "created_at"
		t.datetime "updated_at"
		t.string   "domain"
	end

	add_index "subscriptions_typesobjects", ["subscription_id", "typesobject_id"], :name => "index_subscription_typesobjects_on_subscription_id_and_typesobject_id", :unique => true

	create_table "projects_subscriptions", :id => false, :force => true do |t|
		t.integer  "subscription_id",    :null => false
		t.integer  "project_id",    :null => false
		t.datetime "created_at"
		t.datetime "updated_at"
		t.string   "domain"
	end

	add_index "projects_subscriptions", ["subscription_id", "project_id"], :name => "index_subscription_projects_on_subscription_id_and_project_id", :unique => true

	create_table "groups_subscriptions", :id => false, :force => true do |t|
		t.integer  "subscription_id",    :null => false
		t.integer  "group_id",    :null => false
		t.datetime "created_at"
		t.datetime "updated_at"
		t.string   "domain"
	end

	add_index "groups_subscriptions", ["subscription_id", "group_id"], :name => "index_subscription_groups_on_subscription_id_and_group_id", :unique => true

	create_table "typesobjects", :force => true do |t|
		t.string   "forobject"
		t.string   "name"
		t.string   "fields", :limit => 1024
		t.text     "description"
		t.datetime "created_at"
		t.datetime "updated_at"
		t.string   "domain"
	end

	add_index "typesobjects", ["forobject", "name"], :name => "index_typesobjects_on_object_and_name", :unique => true

	create_table "users", :force => true do |t|
		t.string   "email"
		t.string   "login"
		t.string   "first_name"
		t.string   "last_name"
		t.string   "language"
		t.string   "time_zone"
		t.string   "theme"
		t.string   "hashed_password"
		t.string   "salt"
		t.integer  "role_id"
		t.integer  "volume_id"
		t.integer  "nb_items"
		t.boolean  "last_revision"
		t.boolean  "check_automatic"
		t.boolean  "show_mail"
		t.datetime "created_at"
		t.datetime "updated_at"
		t.integer  "typesobject_id"
		t.integer  "group_id"
		t.integer  "project_id"
		t.string   "domain"
		t.string   "type_values"
		t.integer  "subscription_id"
	end

	add_index "users", ["group_id"], :name => "index_users_on_group_id"
	add_index "users", ["login"], :name => "index_users_on_login", :unique => true
	add_index "users", ["project_id"], :name => "index_users_on_project_id"
	add_index "users", ["role_id"], :name => "index_users_on_role_id"
	add_index "users", ["typesobject_id"], :name => "index_users_on_typesobject_id"
	add_index "users", ["volume_id"], :name => "index_users_on_volume_id"

	create_table "views", :force => true do |t|
		t.string   "name"
		t.text     "description"
		t.datetime "created_at"
		t.datetime "updated_at"
		t.string   "domain"
	end

	add_index "views", ["name"], :name => "index_views_on_name", :unique => true

	create_table "volumes", :force => true do |t|
		t.string   "name"
		t.string   "directory"
		t.string   "protocol"
		t.text     "description"
		t.datetime "created_at"
		t.datetime "updated_at"
		t.string   "domain"
	end

	add_index "volumes", ["name"], :name => "index_volumes_on_name", :unique => true

end
