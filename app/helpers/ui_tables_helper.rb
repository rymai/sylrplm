module UiTablesHelper
	def h_build_table
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug(fname) {"====>@UI_TABLE=#{@UI_TABLE.ident} "}
		LOG.debug(fname) {"====>@object_plms=(true=>ko)#{@object_plms.nil?} "}
		ret=""
		ret+=hidden_field_tag("filter_types" , @myparams["filter_types"]) unless @myparams.nil?
		ret+="<h1>"
		ret+= t("#{controller_name.chop}_list")
		ret+=h_count_objects(@object_plms)
		ret+= "</h1>"
		unless @object_plm.nil?
			form_for(@object_plm) do |f|
				ret+=form_errors_for(@object_plm)
			end
		end
		unless @UI_TABLE.blank?
			columns=@UI_TABLE.get_ui_columns
			ret+=h_form_simple_query("/#{controller_name}", @object_plms, @object_plm)
			ret+=build_form columns
		else
			ret+="<h2>"
			ret+=t(:ui_table_not_define,:controller=>params[:controller],:action=>params[:action])
			ret+="</h2>"
		end
		LOG.debug(fname) {"<==== #{ret.size} characters"}
		ret.html_safe
	end

	def build_form(columns)
		fname= "#{self.class.name}.#{__method__}"
		ret=""
		form_tag({:controller=>controller_name, :action=>:index_execute}) do
			unless param_equals?("todo", "select")
				ret+=h_menu_index_action(controller_name.chop)
			end
			if @myparams[:list_mode] == t(:list_mode_icon)
				ret+=h_thumbnails_objs @object_plms
			else
				objects=@object_plms[:recordset].to_a
				reta=will_paginate(objects).to_s
				LOG.debug(fname) {"will_paginate=#{reta.size} characteres"}
			ret+=reta.to_s
			end
			#
			# table
			#
			ret+= "<table id='list_objects' name='list_objects' class='list_objects'>"
			ret+=  build_header(columns)
			ret+=  build_content(columns)
			ret+=  will_paginate(objects).to_s
			unless param_equals?("todo", "select")
				ret+=h_menu_index_action(controller_name.chop)
			end
			LOG.debug(fname) {"<===="}
		end
		ret
	end

	def build_header(columns)
		fname= "#{self.class.name}.#{__method__}"
		#header
		ret=""
		ret+="<tr class='table_header'>"
		ret+="<th class='table_header'>"
		ret+=h_img(:label_icon)
		ret+= "</th>"
		#
		# loop on columns of the table begin
		#
		columns.each do |col|
			show=show? col
			if(show)
				ret+= "<th class='table_header'"
				if col.sortable
					ret+= sort_td_class_helper('col.ident').to_s
					ret+= ">"
					label="label_#{col.ident}"
					ret+= sort_link_helper(t(label),col.ident).to_s
				else
					ret+= ">"
					label="label_#{col.ident}"
				ret+= col.ident
				end
				ret+="</th>"
			end
		end
		#
		# loop on columns of the table end
		#
		unless param_equals?("todo", "select")
			ret+= "<th>#{h_img_edit}</th>"
			ret+= "<th>#{h_img_edit_lifecycle}</th>"
			ret+= "<th>#{h_img(:duplicate)}</th>"
			ret+= "<th>#{h_img(:copy)}</th>"
			ret+= "<th>#{h_img(:destroy)}</th>"
			ret+= "<th>#{h_img_revise}</th>"
			ret+= "<th>#{h_img(:img_checkout)}</th>"
		end
		ret+= "<th>"
		ret+= t('label_action')
		ret+="</th>"
		ret+="</tr>"
		# fin de header
		ret
	end

	def build_content(columns)
		fname= "#{self.class.name}.#{__method__}"
		ret=""
		# content
		@object_plms[:recordset].each do |object|
			ret+= "<tr class='cycle('even', 'odd')>"
			ret+= "<td>"
			ret+=icone(object)
			ret+= "</td>"
			#
			# loop on columns
			#
			columns.each do |col|
				ret+=build_column object, col
			end
			#
			# right actions menus
			#
			ret+=build_right_action_menus object
			ret+= "</tr>"
		end
		ret+= "</table>"
		ret
	end

	def build_column object, col
		fname= "#{self.class.name}.#{__method__}"
		ret=""
		begin
			show=show? col
			LOG.debug(fname) {"========> begin column"}
			LOG.debug(fname) {"ident=#{col.ident} ,  type_index=#{col.type_index},  type_show=#{col.type_show}"}
			LOG.debug(fname) {"admin_logged_in?=#{admin_logged_in?} , visible_admin=#{col.visible_admin}"}
			LOG.debug(fname) {"logged_in?=#{logged_in?} visible_user=#{col.visible_user}"}
			LOG.debug(fname) {"visible_guest=#{col.visible_guest} "}
			LOG.debug(fname) {"==>> show=#{show} "}
			LOG.debug(fname) {"type_editable=#{col.type_editable} type_editable_file=#{col.type_editable_file} "}
			LOG.debug(fname) {"belong_object=#{col.belong_object} method=#{col.belong_method} "}
			LOG.debug(fname) {"size=#{col.input_size} (#{col.input_size.nil?}) mini=#{col.value_mini} maxi=#{col.value_maxi} "}
			if(show)
				ret+= "<td>"
				unless col.belong_object.blank?
					belong_object=object.send(col.belong_object)
					belong_method=get_belong_method(object, col)
				else
					belong_object=object
					belong_method=get_belong_method(object, col)
				end
				LOG.debug(fname) {"belong_object=#{belong_object} belong_method=#{belong_method} "}
				type_table=@UI_TABLE.type_table
				if(type_table=="index")
				type_col=col.type_index
				end
				if(type_col=="explorer")
					ret+=build_explorer(belong_object,belong_method,col,type_table)
				elsif(type_col=="text")
					ret+=build_text(belong_object,belong_method,col,type_table)
				elsif(type_col=="textarea")
					ret+=build_textarea(belong_object,belong_method,col,type_table)
				elsif(type_col=="comma")
					ret+=build_comma(belong_object,belong_method,col,type_table)
				elsif(type_col=="comma_links")
					ret+=build_comma_links(belong_object,belong_method,col,type_table)
				elsif(type_col=="image")
					ret+=build_image(belong_object,belong_method,col,type_table)
				else
					ret+=build_text(belong_object,belong_method,col,type_table)
				end

				ret+= "</td>"
			else

			# no show: hide the column
				LOG.debug(fname) {"no show: hide the column #{col.ident}"}
			#ret+=<td>"#{col.ident}:hide</td>"
			end
			LOG.debug(fname) {"<======== end column"}

		rescue Exception=> e
			LOG.error(fname){"Warning:#{e}"}
			ret += "#{col.ident}:#{e}"
		end
		ret
	end

	def show? col
		show=false
		if admin_logged_in? && col.visible_admin || logged_in? && col.visible_user ||  col.visible_guest
		show=true
		end
	end

	def build_right_action_menus(object)
		fname="#{self.class.name}.#{__method__}"
		ret=""
		unless param_equals?("todo", "select")
			controller=get_controller_from_model_type(object.modelname)
			ret+= "<td>"
			ret+= link_to( h_img_edit,  {:controller=>controller, :action=>'edit', :id => object.id})
			ret+= "</td>"
			ret+= "<td>"
			begin
				ret+=link_to( h_img_edit_lifecycle, {:controller=>controller, :action=>'edit_lifecycle', :id => object.id})
			rescue Exception => e
				LOG.info(fname){"no lifecycle for #{object}"}
			end
			ret+="</td>"
			ret+= "<td>"
			begin
				ret+= link_to( h_img(:duplicate),  {:controller=>controller, :action=>'new_dup', :id => object.id})
			rescue Exception => e
				LOG.info(fname){"no new dup for #{object}"}
			end
			ret+= "</td>"
			ret+= "<td>"
			if logged_in?
				begin
					ret+=link_to(h_img(:copy),  {:controller=>controller, :action=>'add_clipboard', :id => object.id}, remote: true)
				rescue Exception => e
					LOG.info(fname){"no new add clipboard for #{object}"}
				end
			end
			ret+= "</td>"
			ret+= "<td>"
			ret+= h_destroy(object)
			ret+= "</td>"
			ret+= "<td>"
			if object.revisable?
				ret+=h_img_revise
			end
			ret+= "</td>"
			ret+="<td>"
			if(object.respond_to? :checked?)
				if object.checked?
					ret+=h_img_checkout  if object.checked?
				else
					ret+=h_img_checkin
				end
			else
				ret+="no check"
			end
			ret+="</td>"
			ret+= "<td>#{check_box(:action_on,object.id)}</td>"
		else
			ret+="<td>select_button(object)}</td>"
		end
		ret
	end

	def build_explorer (object,method,col,type_table)
		fname="#{self.class.name}.#{__method__}"
		#LOG.info(fname){"obj=#{obj}, method=#{method}"}
		h_link_to("explorer_obj", object, method)
	end

	def build_comma(object,method,col,type_table)
		fname="#{self.class.name}.#{__method__}"
		LOG.info(fname){"obj=#{obj}, method=#{method}"}
		txt=comma(object, method)
			LOG.debug(fname) {"col truncate before= #{col}"}
		txt=truncate_text(txt,col)
		txt
	end

	def build_comma_links(object,method,col,type_table)
		fname="#{self.class.name}.#{__method__}"
		LOG.info(fname){"object=#{object}, method=#{method} col=#{col.ident}"}
		txt=comma_links(object, method)
			LOG.debug(fname) {"col truncate before= #{col}"}
		txt=truncate_text(txt,col)
		txt
	end

	def build_text(object,method,col,type_table)
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug(fname) {"object=#{object} col=#{col.ident} "}
		begin
			belong_method=get_belong_method(object, col)
			LOG.debug(fname) {"object=#{object} col=#{col.ident} belong_method=#{belong_method}"}
			txt = object.send(belong_method.to_sym)
			LOG.debug(fname) {"col truncate before= #{col}"}
			txt=truncate_text(txt,col)
		rescue Exception=> e
			LOG.error(fname){"Warning:#{e}"}
			txt = "Warning:#{e}"
		end
		txt.to_s
	end

	def build_textarea(object,method,col,type_table)
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug(fname) {"object=#{object} col=#{col.ident} "}
		begin
			belong_method=get_belong_method object, col
			txt = object.send(belong_method.to_sym)
			LOG.debug(fname) {"col truncate before= #{col}"}
			txt=truncate_text(txt,col)
		rescue Exception=> e
			LOG.error(fname){"Warning:#{e}"}
			txt = "!!!!! #{col.ident}"
		end
		ret=text_area(object.modelname,txt)
	end

	def build_image(object,col,type_table)

	end

	def truncate_text(txt,column)
		fname= "#{self.class.name}.#{__method__}"
		ret=txt
		LOG.debug(fname) {"col truncate= #{column}"}
		begin
			unless column.input_size.nil?
				len=column.input_size.to_i
				LOG.debug(fname) {"txt truncate before = #{txt}"}
				ret=truncate(txt,:length=>len) if len>0
				LOG.debug(fname) {"txt truncate after = #{txt}"}
			end
		rescue Exception=>e
			stack=""
			cnt=0
			e.backtrace.each do |x|
				if cnt<10
					stack+= x+"\n"
				end
				cnt+=1
			end
			LOG.debug(fname) {"Error:#{e}\nstack=\n#{stack}\n"}
		end
		ret
	end

	def get_belong_method(object, col)
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug(fname) {"object=#{object} col=#{col.ident} "}
		unless col.belong_method.blank?
		belong_method=col.belong_method
		else
		belong_method=col.ident
		end
		LOG.debug(fname) {"object=#{object} col=#{col.ident} belong_method=#{belong_method}"}
		belong_method
	end
end