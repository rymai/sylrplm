# frozen_string_literal: true

json.extract! ui_table, :id, :ident, :type, :description, :pagination, :title, :created_at, :updated_at
json.url ui_table_url(ui_table, format: :json)
