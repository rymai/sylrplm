# frozen_string_literal: true

module UiTablesHelper
  def h_build_table
    fname = "#{self.class.name}.#{__method__}"
    LOG.debug(fname) { "====>@object_plms=(true=>ko)#{@object_plms.nil?} " }
    ret = ''
    ret += hidden_field_tag('filter_types', @myparams['filter_types']) unless @myparams.nil?
    ret += '<h1>'
    ret += t("#{controller_name.chop}_list")
    ret += h_count_objects(@object_plms)
    ret += '</h1>'
    unless @object_plm.nil?
      form_for(@object_plm) do |_f|
        ret += form_errors_for(@object_plm)
      end
    end
    if @UI_TABLE.blank?
      ret += '<h2>'
      ret += t(:ui_table_not_define, controller: params[:controller], action: params[:action])
      ret += '</h2>'
    else
      LOG.debug(fname) { "====>@UI_TABLE=#{@UI_TABLE.ident} " }
      columns = @UI_TABLE.get_ui_columns
      LOG.debug(fname) { "====>columns=#{columns.size}" }
      ret += h_form_simple_query("/#{controller_name}", @object_plms, @object_plm)
      ret += build_form(columns)
    end
    LOG.debug(fname) { "<==== #{ret.size} characters" }
    ret.html_safe
  end

  def build_form(columns)
    fname = "#{self.class.name}.#{__method__}"
    ret = ''
    form_tag(controller: controller_name, action: :index_execute) do
      unless param_equals?('todo', 'select')
        ret += h_menu_index_action(controller_name.chop)
      end
      if @myparams[:list_mode] == t(:list_mode_icon)
        ret += h_thumbnails_objs @object_plms
      else
        objects = @object_plms[:recordset].to_a
        reta = will_paginate(objects).to_s
        LOG.debug(fname) { "will_paginate=#{reta.size} characteres" }
        ret += reta.to_s
      end
      #
      # table
      #
      ret += "<table id='list_objects' name='list_objects' class='list_objects'>"
      ret += build_header(columns)
      ret += build_content(columns)
      ret += will_paginate(objects).to_s
      unless param_equals?('todo', 'select')
        ret += h_menu_index_action(controller_name.chop)
      end
      LOG.debug(fname) { '<====' }
    end
    ret
  end

  def build_header(columns)
    fname = "#{self.class.name}.#{__method__}"
    # header
    ret = ''
    ret += "<tr class='table_header'>"
    ret += "<th class='table_header'>"
    ret += h_img(:label_icon)
    ret += '</th>'
    #
    # loop on columns of the table begin
    #
    columns.each do |col|
      show = show? col
      next unless show
      ret += "<th class='table_header'"
      label = t("label_#{col.ident}")
      if col.sortable
        ret += sort_td_class_helper('col.ident').to_s
        ret += '>'
        ret += sort_link_helper(label, col.ident).to_s
      else
        ret += '>'
        ret += label
      end
      ret += '</th>'
    end
    #
    # loop on columns of the table end
    #
    unless param_equals?('todo', 'select')
      ret += "<th>#{h_img_edit}</th>"
      ret += "<th>#{h_img_edit_lifecycle}</th>"
      ret += "<th>#{h_img(:duplicate)}</th>"
      ret += "<th>#{h_img(:copy)}</th>"
      ret += "<th>#{h_img(:destroy)}</th>"
      ret += "<th>#{h_img_revise}</th>"
      ret += "<th>#{h_img(:img_checkout)}</th>"
    end
    ret += '<th>'
    ret += t('label_action')
    ret += '</th>'
    ret += '</tr>'
    # fin de header
    ret
  end

  def build_content(columns)
    fname = "#{self.class.name}.#{__method__}"
    ret = ''
    # content
    @object_plms[:recordset].each do |object|
      ret += "<tr class='cycle('even', 'odd')>"
      ret += '<td>'
      ret += icone(object)
      ret += '</td>'
      #
      # loop on columns
      #
      columns.each do |col|
        ret += build_column object, col
      end
      #
      # right actions menus
      #
      ret += build_right_action_menus object
      ret += '</tr>'
    end
    ret += '</table>'
    ret
  end

  def build_column(object, col)
    fname = "#{self.class.name}.#{__method__}"
    ret = ''
    begin
      show = show? col
      LOG.debug(fname) { '========> begin column' }
      LOG.debug(fname) { "ident=#{col.ident} ,  type_index=#{col.type_index},  type_show=#{col.type_show}" }
      LOG.debug(fname) { "admin_logged_in?=#{admin_logged_in?} , visible_admin=#{col.visible_admin}" }
      LOG.debug(fname) { "logged_in?=#{logged_in?} visible_user=#{col.visible_user}" }
      LOG.debug(fname) { "visible_guest=#{col.visible_guest} " }
      LOG.debug(fname) { "==>> show=#{show} " }
      LOG.debug(fname) { "type_editable=#{col.type_editable} type_editable_file=#{col.type_editable_file} " }
      LOG.debug(fname) { "belong_object=#{col.belong_object} method=#{col.belong_method} " }
      LOG.debug(fname) { "size=#{col.input_size} (#{col.input_size.nil?}) mini=#{col.value_mini} maxi=#{col.value_maxi} " }
      if show
        ret += '<td>'
        if col.belong_object.blank?
          belong_object = object
          belong_method = get_belong_method(object, col)
        else
          belong_object = object.send(col.belong_object)
          belong_method = get_belong_method(object, col)
        end
        LOG.debug(fname) { "belong_object=#{belong_object} belong_method=#{belong_method} " }
        type_table = @UI_TABLE.type_table
        type_col = col.type_index if type_table == 'index'
        ret += if type_col == 'explorer'
                 build_explorer(belong_object, belong_method, col, type_table)
               elsif type_col == 'text'
                 build_text(belong_object, belong_method, col, type_table)
               elsif type_col == 'textarea'
                 build_textarea(belong_object, belong_method, col, type_table)
               elsif type_col == 'comma'
                 build_comma(belong_object, belong_method, col, type_table)
               elsif type_col == 'comma_links'
                 build_comma_links(belong_object, belong_method, col, type_table)
               elsif type_col == 'image'
                 build_image(belong_object, belong_method, col, type_table)
               else
                 build_text(belong_object, belong_method, col, type_table)
               end

        ret += '</td>'
      else

        # no show: hide the column
        LOG.debug(fname) { "no show: hide the column #{col.ident}" }
        # ret+=<td>"#{col.ident}:hide</td>"
      end
      LOG.debug(fname) { '<======== end column' }
    rescue Exception => e
      LOG.warn(fname) { "Warning:#{e}" }
      ret += "#{col.ident}:#{e}"
      LOG.warn(fname) { "stack=#{e.backtrace.join("\n")}" }
    end
    ret
  end

  def build_right_action_menus(object)
    fname = "#{self.class.name}.#{__method__}"
    ret = ''
    unless mobile?
      if param_equals?('todo', 'select')
        ret += '<td>select_button(object)}</td>'
      else
        controller = get_controller_from_model_type(object.modelname)
        ret += '<td>'
        ret += link_to(h_img_edit, controller: controller, action: 'edit', id: object.id)
        ret += '</td>'
        ret += '<td>'
        begin
          ret += link_to(h_img_edit_lifecycle, controller: controller, action: 'edit_lifecycle', id: object.id)
        rescue Exception => e
          LOG.info(fname) { "no lifecycle for #{object}" }
        end
        ret += '</td>'
        ret += '<td>'
        begin
          ret += link_to(h_img(:duplicate), controller: controller, action: 'new_dup', id: object.id)
        rescue Exception => e
          LOG.info(fname) { "no new dup for #{object}" }
        end
        ret += '</td>'
        ret += '<td>'
        if logged_in?
          begin
            ret += link_to(h_img(:copy),  { controller: controller, action: 'add_clipboard', id: object.id }, remote: true)
          rescue Exception => e
            LOG.info(fname) { "no new add clipboard for #{object}" }
          end
        end
        ret += '</td>'
        ret += '<td>'
        ret += h_destroy(object)
        ret += '</td>'
        ret += '<td>'
        if object.respond_to? :revisable
          ret += h_img_revise if object.revisable?
        end
        ret += '</td>'
        ret += '<td>'
        ret +=
          if object.respond_to?(:checked?)
            if object.checked?
              h_img_checkout
            else
              h_img_checkin
            end
          else
            'no check'
          end
        ret += '</td>'
        ret += "<td>#{check_box(:action_on, object.id)}</td>"
      end
    end
    ret
  end

  def build_explorer(object, method, _col, _type_table)
    fname = "#{self.class.name}.#{__method__}"
    # LOG.info(fname){"obj=#{obj}, method=#{method}"}
    h_link_to('explorer_obj', object, method)
  end

  def build_comma(object, method, col, _type_table)
    fname = "#{self.class.name}.#{__method__}"
    LOG.info(fname) { "object=#{object}, method=#{method}" }
    txt = comma_string(object, method)
    LOG.debug(fname) { "col truncate before= #{col}" }
    txt = truncate_text(txt, col)
    txt
  end

  def build_comma_links(object, method, col, _type_table)
    fname = "#{self.class.name}.#{__method__}"
    LOG.info(fname) { "object=#{object}, method=#{method} col=#{col.ident}" }
    txt = comma_links(object, method)
    LOG.debug(fname) { "col truncate before= #{col}" }
    txt = truncate_text(txt, col)
    txt
  end

  def build_text(object, _method, col, _type_table)
    fname = "#{self.class.name}.#{__method__}"
    LOG.debug(fname) { "object=#{object} col=#{col.ident} " }
    begin
      belong_method = get_belong_method(object, col)
      LOG.debug(fname) { "object=#{object} col=#{col.ident} belong_method=#{belong_method}" }
      txt = object.send(belong_method.to_sym)
      LOG.debug(fname) { "col truncate before= #{col}" }
      txt = truncate_text(txt, col)
    rescue Exception => e
      LOG.error(fname) { "Warning:#{e}" }
      txt = "Warning:#{e}"
    end
    txt.to_s
  end

  def build_textarea(object, _method, col, _type_table)
    fname = "#{self.class.name}.#{__method__}"
    LOG.debug(fname) { "object=#{object} col=#{col.ident} " }
    begin
      belong_method = get_belong_method object, col
      txt = object.send(belong_method.to_sym)
      LOG.debug(fname) { "col truncate before= #{col}" }
      txt = truncate_text(txt, col)
    rescue Exception => e
      LOG.error(fname) { "Warning:#{e}" }
      txt = "!!!!! #{col.ident}"
    end
    ret = text_area(object.modelname, txt)
  end

  def build_image(object, col, type_table); end
end
