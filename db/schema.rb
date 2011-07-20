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

ActiveRecord::Schema.define(:version => 20110623185426) do

  create_table "accesses", :force => true do |t|
    t.string   "controller"
    t.string   "action"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "roles"
  end

  add_index "accesses", ["controller"], :name => "id_access_controller"

  create_table "ar_workitems", :force => true do |t|
    t.string   "fei"
    t.string   "wfid"
    t.string   "expid"
    t.string   "wfname"
    t.string   "wfrevision"
    t.string   "participant_name"
    t.string   "store_name"
    t.datetime "dispatch_time"
    t.datetime "last_modified"
    t.text     "wi_fields"
    t.string   "activity"
    t.text     "keywords"
  end

  add_index "ar_workitems", ["expid"], :name => "index_ar_workitems_on_expid"
  add_index "ar_workitems", ["fei"], :name => "index_ar_workitems_on_fei"
  add_index "ar_workitems", ["participant_name"], :name => "index_ar_workitems_on_participant_name"
  add_index "ar_workitems", ["store_name"], :name => "index_ar_workitems_on_store_name"
  add_index "ar_workitems", ["wfid"], :name => "index_ar_workitems_on_wfid"
  add_index "ar_workitems", ["wfname"], :name => "index_ar_workitems_on_wfname"
  add_index "ar_workitems", ["wfrevision"], :name => "index_ar_workitems_on_wfrevision"

  create_table "checks", :force => true do |t|
    t.string   "object"
    t.integer  "object_id"
    t.integer  "status"
    t.string   "out_reason"
    t.date     "out_date"
    t.integer  "out_user"
    t.string   "in_reason"
    t.date     "in_date"
    t.integer  "in_user"
    t.string   "local_dir"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "checks", ["object", "object_id"], :name => "id_check_object"

  create_table "customers", :force => true do |t|
    t.string   "ident"
    t.string   "designation"
    t.text     "description"
    t.string   "group"
    t.date     "date"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "typesobject_id"
    t.integer  "statusobject_id"
    t.integer  "owner_id"
  end

  add_index "customers", ["ident"], :name => "id_customer_ident"
  add_index "customers", ["owner_id"], :name => "fk_customer_owner"
  add_index "customers", ["statusobject_id"], :name => "fk_customer_status"
  add_index "customers", ["typesobject_id"], :name => "fk_customer_type"

  create_table "datafiles", :force => true do |t|
    t.string   "ident"
    t.string   "filename"
    t.integer  "revision"
    t.integer  "typesobject_id"
    t.string   "content_type"
    t.integer  "owner_id"
    t.integer  "volume_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "document_id"
  end

  add_index "datafiles", ["document_id"], :name => "fk_datafile_document"
  add_index "datafiles", ["ident"], :name => "id_datafile_ident"

  create_table "definitions", :force => true do |t|
    t.string   "name"
    t.string   "description"
    t.string   "uri"
    t.text     "launch_fields"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "definitions", ["name"], :name => "index_definitions_on_name", :unique => true

  create_table "documents", :force => true do |t|
    t.string   "ident"
    t.string   "revision"
    t.string   "designation"
    t.text     "description"
    t.string   "group"
    t.date     "date"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "typesobject_id"
    t.integer  "statusobject_id"
    t.integer  "owner_id"
  end

  add_index "documents", ["ident"], :name => "id_document_ident"
  add_index "documents", ["owner_id"], :name => "fk_document_owner"
  add_index "documents", ["statusobject_id"], :name => "fk_document_status"
  add_index "documents", ["typesobject_id"], :name => "fk_document_type"

  create_table "forum_items", :force => true do |t|
    t.text     "message"
    t.integer  "forum_id"
    t.integer  "parent_id"
    t.integer  "owner_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "forum_items", ["forum_id"], :name => "index_forum_items_on_forum_id"
  add_index "forum_items", ["owner_id"], :name => "index_forum_items_on_owner_id"
  add_index "forum_items", ["parent_id"], :name => "index_forum_items_on_parent_id"

  create_table "forums", :force => true do |t|
    t.integer  "statusobject_id"
    t.string   "subject"
    t.text     "description"
    t.integer  "owner_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "typesobject_id"
  end

  add_index "forums", ["owner_id"], :name => "index_forums_on_owner_id"
  add_index "forums", ["statusobject_id"], :name => "index_forums_on_statusobject_id"
  add_index "forums", ["typesobject_id"], :name => "index_forums_on_typesobject_id"

  create_table "group_definitions", :force => true do |t|
    t.integer  "group_id"
    t.integer  "definition_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "groups", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "groups", ["name"], :name => "index_groups_on_name", :unique => true

  create_table "history", :force => true do |t|
    t.datetime "created_at"
    t.string   "source",      :null => false
    t.string   "event",       :null => false
    t.string   "wfid"
    t.string   "wfname"
    t.string   "wfrevision"
    t.string   "fei"
    t.string   "participant"
    t.string   "message"
    t.text     "tree"
  end

  add_index "history", ["created_at"], :name => "index_history_on_created_at"
  add_index "history", ["event"], :name => "index_history_on_event"
  add_index "history", ["participant"], :name => "index_history_on_participant"
  add_index "history", ["source"], :name => "index_history_on_source"
  add_index "history", ["wfid"], :name => "index_history_on_wfid"
  add_index "history", ["wfname"], :name => "index_history_on_wfname"
  add_index "history", ["wfrevision"], :name => "index_history_on_wfrevision"

  create_table "links", :force => true do |t|
    t.string   "father_type"
    t.string   "child_type"
    t.integer  "father_id"
    t.integer  "child_id"
    t.string   "name"
    t.string   "designation"
    t.text     "description"
    t.string   "responsible"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "links", ["child_type", "child_id"], :name => "id_link_child"
  add_index "links", ["father_type", "father_id"], :name => "id_link_father"

  create_table "notifications", :force => true do |t|
    t.string   "object_type"
    t.integer  "object_id"
    t.date     "event_date"
    t.text     "event_type"
    t.integer  "responsible_id"
    t.date     "notify_date"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "parts", :force => true do |t|
    t.string   "ident"
    t.string   "revision"
    t.string   "designation"
    t.text     "description"
    t.string   "group"
    t.date     "date"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "typesobject_id"
    t.integer  "statusobject_id"
    t.integer  "owner_id"
  end

  add_index "parts", ["ident"], :name => "id_part_ident"
  add_index "parts", ["owner_id"], :name => "fk_part_owner"
  add_index "parts", ["statusobject_id"], :name => "fk_part_status"
  add_index "parts", ["typesobject_id"], :name => "fk_part_type"

  create_table "process_errors", :force => true do |t|
    t.datetime "created_at"
    t.string   "wfid",       :null => false
    t.string   "expid",      :null => false
    t.text     "svalue",     :null => false
  end

  add_index "process_errors", ["created_at"], :name => "index_process_errors_on_created_at"
  add_index "process_errors", ["expid"], :name => "index_process_errors_on_expid"
  add_index "process_errors", ["wfid"], :name => "index_process_errors_on_wfid"

  create_table "projects", :force => true do |t|
    t.string   "ident"
    t.string   "designation"
    t.text     "description"
    t.string   "group"
    t.date     "date"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "typesobject_id"
    t.integer  "statusobject_id"
    t.integer  "owner_id"
  end

  add_index "projects", ["ident"], :name => "id_project_ident"
  add_index "projects", ["owner_id"], :name => "fk_project_owner"
  add_index "projects", ["statusobject_id"], :name => "fk_project_status"
  add_index "projects", ["typesobject_id"], :name => "fk_project_type"

  create_table "questions", :force => true do |t|
    t.string   "question"
    t.string   "answer"
    t.integer  "position"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "roles", :force => true do |t|
    t.string   "title"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "roles_users", :id => false, :force => true do |t|
    t.integer  "role_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "roles_users", ["role_id"], :name => "id_role_role"
  add_index "roles_users", ["user_id"], :name => "id_role_user"

  create_table "sequences", :force => true do |t|
    t.string   "value"
    t.string   "min"
    t.string   "max"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "utility"
    t.boolean  "modify"
    t.boolean  "sequence"
  end

  add_index "sequences", ["utility"], :name => "id_sequence_utility", :unique => true

  create_table "sessions", :force => true do |t|
    t.string   "session_id",                       :null => false
    t.text     "data",       :limit => 2147483647
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "statusobjects", :force => true do |t|
    t.string   "object"
    t.string   "name"
    t.integer  "rank"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "promote"
    t.boolean  "demote"
  end

  add_index "statusobjects", ["object", "rank", "name"], :name => "id_statusobject_object", :unique => true

  create_table "typesobjects", :force => true do |t|
    t.string   "object"
    t.string   "name"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "typesobjects", ["object", "name"], :name => "id_typesobject_object", :unique => true

  create_table "user_groups", :force => true do |t|
    t.integer "user_id",  :null => false
    t.integer "group_id", :null => false
  end

  add_index "user_groups", ["user_id", "group_id"], :name => "index_user_groups_on_user_id_and_group_id", :unique => true

  create_table "users", :force => true do |t|
    t.string   "login"
    t.string   "hashed_password"
    t.string   "salt"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "role_id"
    t.string   "email"
    t.string   "theme"
    t.integer  "volume_id"
    t.integer  "nb_items"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "language"
    t.integer  "notification"
    t.boolean  "show_mail"
    t.string   "time_zone"
  end

  add_index "users", ["login"], :name => "id_user_login", :unique => true
  add_index "users", ["role_id"], :name => "fk_user_role"
  add_index "users", ["role_id"], :name => "index_users_on_role_id"
  add_index "users", ["volume_id"], :name => "index_users_on_volume_id"

  create_table "volumes", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.string   "directory"
    t.string   "protocole"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
