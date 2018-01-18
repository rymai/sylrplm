# frozen_string_literal: true

#
# export
#
def export_table(table)
  fname = "#{self.class.name}.#{__method__}"
  ret = ''
  LOG.debug(fname) { "====>@UI_TABLE=#{table.ident} " }
  if table.blank?
    ret += t(:ui_table_not_define, controller: params[:controller], action: params[:action])
  else
    columns = table.get_ui_columns
    LOG.debug(fname) { "====>columns=#{columns.size} " }
    ret += export_header(columns)
    ret += export_content(columns)
  end
  LOG.debug(fname) { "<==== #{ret.size} characters" }
  ret.html_safe
end

def export_header(columns)
  fname = "#{self.class.name}.#{__method__}"
  # header
  ret = ''
  # ::SYLRPLM::EXPORT_COLUMN_SEP
  # loop on columns of the table begin
  #
  columns.each do |col|
    ret += col.ident + ::SYLRPLM::EXPORT_COLUMN_SEP if show? col
  end
  ret += "\n"
  # fin de header
  ret
end

def export_content(columns)
  fname = "#{self.class.name}.#{__method__}"
  ret = ''
  # content
  @object_plms[:recordset].each do |object|
    #
    # loop on columns
    #
    columns.each do |col|
      next unless show? col
      LOG.debug(fname) { "1 object=#{object} col=#{col} " }
      unless object.blank?
        LOG.debug(fname) { "2 object=#{object} col=#{col} " }
        ret += export_column(object, col) + ::SYLRPLM::EXPORT_COLUMN_SEP
      end
    end
    ret += "\n"
  end
  ret
end

def export_column(object, col)
  fname = "#{self.class.name}.#{__method__}"
  LOG.debug(fname) { "3 object=#{object} col=#{col} " }
  ret = ''
  begin
    show = show? col
    if show
      if col.belong_object.blank?
        belong_object = object
        belong_method = get_belong_method(object, col)
      else
        belong_object = object.send(col.belong_object)
        belong_object = object if belong_object.nil?
        belong_method = get_belong_method(object, col)
      end
      LOG.debug(fname) { "belong_object=#{belong_object} belong_method=#{belong_method} " }
      type_table = @UI_TABLE.type_table
      if type_table == 'index'
        type_col = col.type_index
        type_col = 'text' if type_col.nil?
      end
      if type_col == 'explorer'
        ret += export_explorer(belong_object, belong_method, col, type_table)
      elsif type_col == 'text'
        ret += export_text(belong_object, belong_method, col, type_table)
      elsif type_col == 'comma'
        ret += export_comma(belong_object, belong_method, col, type_table)
      end
    end
  rescue Exception => e
    LOG.warn(fname) { "Warning:#{e}" }
    ret += "#{col.ident}:#{e}"
    LOG.warn(fname) { "stack=#{e.backtrace.join("\n")}" }
  end
  ret
end

def export_explorer(object, method, _col, _type_table)
  fname = "#{self.class.name}.#{__method__}"
  LOG.info(fname) { "object=#{object}, method=#{method}" }
  # h_link_to("explorer_obj", object, method)
  object.send(method.to_sym)
end

def export_comma(object, method, _col, _type_table)
  fname = "#{self.class.name}.#{__method__}"
  LOG.info(fname) { "object=#{object}, method=#{method}" }
  comma_string(object, method)
end

def export_text(object, method, col, _type_table)
  fname = "#{self.class.name}.#{__method__}"
  LOG.debug(fname) { "object=#{object} col=#{col.ident} " }
  txt = ''
  belong_method = get_belong_method(object, col)
  # belong_method=col.ident
  LOG.debug(fname) { "object=#{object} col=#{col.ident} method=#{method}" }
  txt = object.send(belong_method.to_sym)
  txt.to_s
end

def show?(col)
  show = false
  if admin_logged_in? && col.visible_admin || logged_in? && col.visible_user || col.visible_guest
    show = true
  end
end

def truncate_text(txt, column)
  fname = "#{self.class.name}.#{__method__}"
  ret = txt
  LOG.debug(fname) { "col truncate= #{column}" }
  begin
    unless column.input_size.nil?
      len = column.input_size.to_i
      LOG.debug(fname) { "txt truncate before = #{txt}" }
      ret = truncate(txt, length: len) if len > 0
      LOG.debug(fname) { "txt truncate after = #{txt}" }
    end
  rescue Exception => e
    stack = ''
    cnt = 0
    e.backtrace.each do |x|
      stack += x + "\n" if cnt < 10
      cnt += 1
    end
    LOG.debug(fname) { "Error:#{e}\nstack=\n#{stack}\n" }
  end
  ret
end

def get_belong_method(object, col)
  fname = "#{self.class.name}.#{__method__}"
  LOG.debug(fname) { "object=#{object} col=#{col.ident} " }
  belong_method = if col.belong_method.blank?
                    col.ident
                  else
                    col.belong_method
                  end
  LOG.debug(fname) { "object=#{object} col=#{col.ident} belong_method=#{belong_method}" }
  belong_method
end

#
# build a set of strings separated by a comma
# each part of the string is composed of the accessor applicated on the object
def comma_string(objects, accessor = :name)
  objects.collect do |o|
    o.send(accessor)
  end.join(', ')
  end
