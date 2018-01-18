# frozen_string_literal: true

json.extract! ui_column, :id, :ident, :type, :description, :title, :visible_user, :visible_admin, :visible_support, :editable, :type_show, :type_editable, :type_editable_file, :created_at, :updated_at
json.url ui_column_url(ui_column, format: :json)
