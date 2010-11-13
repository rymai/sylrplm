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

ActiveRecord::Schema.define(:version => 20101102170703) do

  create_table "accesses", :force => true do |t|
    t.string   "controller"
    t.string   "action"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "roles"
  end

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
    t.integer  "owner"
  end

  add_index "customers", ["owner"], :name => "fk_customer_owner"
  add_index "customers", ["statusobject_id"], :name => "fk_customer_status"
  add_index "customers", ["typesobject_id"], :name => "fk_customer_type"

  create_table "documents", :force => true do |t|
    t.string   "ident"
    t.string   "revision"
    t.string   "designation"
    t.text     "description"
    t.string   "extension"
    t.string   "repository"
    t.string   "group"
    t.date     "date"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "part_id"
    t.string   "filename"
    t.binary   "data",            :limit => 16777215
    t.string   "content_type"
    t.integer  "typesobject_id"
    t.integer  "statusobject_id"
    t.integer  "volume"
    t.integer  "volume_id"
    t.integer  "owner"
  end

  add_index "documents", ["owner"], :name => "fk_document_owner"
  add_index "documents", ["part_id"], :name => "fk_document_part"
  add_index "documents", ["statusobject_id"], :name => "fk_document_status"
  add_index "documents", ["typesobject_id"], :name => "fk_document_type"
  add_index "documents", ["volume_id"], :name => "fk_document_volume"

  create_table "forum_items", :force => true do |t|
    t.text     "message"
    t.integer  "forum_id"
    t.integer  "parent_id"
    t.integer  "owner_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "forums", :force => true do |t|
    t.integer  "statusobject_id"
    t.string   "subject"
    t.text     "description"
    t.integer  "owner_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "typesobject_id"
  end

  create_table "links", :force => true do |t|
    t.string   "father_object"
    t.string   "child_object"
    t.integer  "father_id"
    t.integer  "child_id"
    t.string   "name"
    t.string   "designation"
    t.text     "description"
    t.string   "responsible"
    t.string   "group"
    t.date     "date"
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
    t.integer  "owner"
  end

  add_index "parts", ["owner"], :name => "fk_part_owner"
  add_index "parts", ["statusobject_id"], :name => "fk_part_status"
  add_index "parts", ["typesobject_id"], :name => "fk_part_type"

  create_table "projects", :force => true do |t|
    t.string   "ident"
    t.string   "designation"
    t.text     "description"
    t.string   "group"
    t.date     "date"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "customer_id"
    t.integer  "typesobject_id"
    t.integer  "statusobject_id"
    t.integer  "owner"
  end

  add_index "projects", ["customer_id"], :name => "fk_project_customer"
  add_index "projects", ["owner"], :name => "fk_project_owner"
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

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
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

  create_table "typesobjects", :force => true do |t|
    t.string   "object"
    t.string   "name"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", :force => true do |t|
    t.string   "login"
    t.string   "hashed_password"
    t.string   "salt"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "role_id"
    t.string   "email"
    t.string   "theme"
  end

  add_index "users", ["role_id"], :name => "fk_user_role"

  create_table "volumes", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.string   "directory"
    t.string   "protocole"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
