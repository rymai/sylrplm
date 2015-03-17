###require "string_to_sha1/version"
require "digest/sha1"

# = ApplicationHelper
# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
	#
	# select on type for update_type by Ajax
	#
	def h_edit_type_object(form, object, types)
		fname=self.class.name+"."+__method__.to_s
		#LOG.debug (fname){"object=#{object.inspect}"}
		#LOG.debug (fname){"types=#{types} "}
		option_readonly ={:readonly => object.column_readonly?(:typesobject_id)}
		unless object.id.nil?
			url={:controller => get_controller_from_model_type(object.model_name), :action => "update_type",:id=>object.id}
			#LOG.debug (fname){"url=#{url} "}
			with = "'object_type='+value"
			option_onchange={:onchange => remote_function(:url  => url, :with => with)}
		else
			option_onchange=nil
		end
		ret = ""
		ret << form.label(t("label_type"))
		unless option_onchange.nil?
			ret << form.collection_select(:typesobject_id, types, :id, :name,option_readonly, option_onchange)
		else
			ret << form.collection_select(:typesobject_id, types, :id, :name,option_readonly)
		end
		ret << "</br>"
		ret
	end

	def h_show_translate item
		" (#{item})"
	end

	def h_menu_duplicate(object_plm)
		# new_dup_customer_path
		url="{new_dup_object_plm.model_name}_path"
		link_to h_img(:duplicate),  {:controller => object_plm.controller_name, :action => :new_dup, :id => object_plm.id}
	end

	def h_edit_lifecycle(a_form, a_object)
		render(
		:partial => "shared/lifecycle_edit",
		:locals => {:a_form => a_form, :a_object => a_object}
		)
	end

	#
	# == Role: prepare a title
	# == Arguments
	# * +text+ - text for title
	# == Usage
	# === Calling view
	# === Result
	# == Impact on other components
	#
	def h_title(text)
		content_for :title, text
	end

	def h_value_or_default(value, default)
		ret = default
		unless value.nil?
		ret = value unless value.size==0
		end
		ret
	end

	#
	# Renvoie la valeur de l'attribut att sur current si
	# 1- current n'a pas le meme identifiant que previous
	# 2- que les valeurs de l'attribut sont differentes entre les 2objets
	# att peut etre un attribut "compose" tel que owner.login
	def h_if_differ_trop_general_obsolete(current, previous)
		ret = current
		unless previous.nil?
			if current == previous
				ret= ""
			end
		end
		ret
	end

	def h_if_differ(current, previous)
		current
	end

	# renvoie la valeur de l'attribut att sur l'objet
	# att peut etre un attribut "compose" tel que owner.login, d'ou l'utilisation de eval
	def get_val(obj, att)
		blk = "obj = #{obj.class.name}.find(#{obj.id})\nobj.#{att}"
		#puts "blk="+blk
		ret = eval blk
		ret
	end

	def h_menu(href,help,title)
		bloc=""
		#ne marche pas avec boostrap bloc<<"<a class='menu' onclick=\"return helpPopup('#{help}','#{href}');\" >#{title}</a>";
		bloc<<"<a class='menu' href='#{href}' >#{title}</a>";
		bloc
	end

	def h_count_objects(objects)
		unless objects[:page].nil?
			num_begin=(objects[:page].to_i-1)
		else
		num_begin=0
		end
		num_begin*=objects[:nb_items].to_i
		num_begin+=1
		num_end=num_begin+objects[:recordset].length-1
		t("count_objects",:number_begin=>num_begin,:number_end=>num_end,:total=>objects[:total])
	end

	def h_form_simple_query(url, objects)
		render(
		:partial => "shared/form_simple_query",
		:locals => {:url => url, :objects => objects}
		)
	end

	def h_thumbnails_objs(objs)
		ret = ""
		objs[:recordset].each do |obj|
			ret << "<span class='thumbnail'>"
			ret << h_explorer(obj, :ident)
			ret << icone(obj)
			ret << "</span>"
		end
		ret
	end

	def h_img_path(name)
		"<img src=\"#{name}\"></img>"
	end

	def h_image(name, title=nil)
		if title.nil?
			title=t(File.basename(name.to_s))
		end
		h_img_base(name, title, "image")
	end

	def h_img(name, title=nil)
		if title.nil?
			title=t(File.basename(name.to_s))
		end
		h_img_base(name, title, "icone")
	end

	def h_img_btn(name)
		title=t(File.basename(name.to_s))
		h_img_base(name, title, "btn")
	end

	def h_img_tit(name, title)
		h_img_base(name, title, "icone")
	end

	def h_img_base(name, title, cls)
		"<img class='#{cls}' src='/images/#{name}.png' title='#{title}'/>"
	end

	def h_img_cut
		h_img("cut")
	end

	def h_img_destroy
		h_img("destroy")
	end

	def h_img_checkout
		h_img("img_checkout")
	end

	def h_img_checkin
		h_img("img_checkin")
	end

	def h_img_edit
		h_img("edit")
	end

	def h_img_edit_task
		h_img("edit_task")
	end

	def h_img_show
		h_img("explorer")
	end

	def h_img_launch
		h_img("launch")
	end

	def h_img_launchthis
		h_img("launchthis")
	end

	def h_img_revise
		h_img("revise")
	end

	def h_img_add_projects
		h_img("paste_projects")
	end

	def h_img_add_documents
		h_img("paste_documents")
	end

	def h_img_add_parts
		h_img("paste_parts")
	end

	def h_img_add_forum
		h_img("add_forum")
	end

	def h_img_list
		h_img("list")
	end

	def h_img_abort
		h_img("abort")
	end

	def h_img_edit_lifecycle
		h_img("edit_lifecycle")
	end

	def h_img_all
		h_img("all")
	end

	def h_img_pick
		h_img("pick")
	end

	def h_img_sub(name)
		image_submit_tag(name.to_s+".png",:title=>t(name), :class=>"submit")
	end

	def h_explorer (obj, method = nil)
		fname=self.class.name+"."+__method__.to_s
		#LOG.info (fname){"obj=#{obj}, method=#{method}"}
		h_link_to("explorer_obj", obj, method)
	end

	def h_link_to (name, obj, method = nil)
		fname=self.class.name+"."+__method__.to_s
		#LOG.info (fname){"name=#{name} obj=#{obj}, method=#{method}"}
		ret=""
		begin
			unless obj.nil?
				if method.nil?
					method = "ident"
				end
				begin
					txt = obj.send(method.to_sym)
				rescue Exception=> e
				txt = obj.ident
				end
				if txt.blank?
				txt = obj.to_s
				end
				title = t(name, :obj => obj)
				ret=link_to( txt, obj, {:title => title } )
			#LOG.info (fname){"name=#{name} obj=#{obj}, model=#{obj.model_name} , method=#{method} respond?=#{obj.respond_to?(method)} , txt=#{txt} , ret=#{ret}"}
			end
		rescue Exception => e
			LOG.error (fname){"exception name=#{name}  method=#{method} error=#{e}"}
		end
		return ret
	end

	def h_destroy(obj)
		link_to( h_img_destroy.to_s, obj, :confirm => t(:msg_confirm), :method => :delete)
	end

	def sort_td_class_helper(param)
		result = 'class="sortup"' if params[:sort] == param
		result = 'class="sortdown"' if params[:sort] == param.to_s + " DESC"
		result
	end

	def sort_link_helper(text, param)
		key = param
		key += " DESC" if params[:sort] == param
		#
		#DEPRECATION WARNING: The :overwrite_params option is deprecated. Specify all the necessary parameters instead.
		#old url = {:overwrite_params => {:sort => key, :page => nil}}
		url = params.merge(:sort => key, :page => nil)
		options = {
			:url => url,
			:update => 'table',
			:before => "Element.show('spinner')",
			:success => "Element.hide('spinner')"
		}
		html_options = {
			:title => t("h_sort_by_field"),
			:href => url_for(:action => 'index', :params => params.merge({:sort => key, :page => nil}))
		}
		link_to_remote(text, options, html_options)
	end

	#
	# translate the second part of the message (after ":")
	# => send the first part as a translate variable
	# exemple : notifications.send_notifications send "#{user.login}:#{msg}", msg could be nothing_to_notify,mail_delivered or mail_not_created
	def h_tr_messag(msg)
		fname=self.class.name+"."+__method__.to_s
		ret=""
		unless msg.blank?
			msg.split(",").each do |u|
			#LOG.info (fname){"part of message=#{u}"}
				fields = u.split(":")
				ret += "," unless ret.blank?
				if fields.count>1
					ret += t(fields[1], :var => fields[0])
				else
				ret += fields[0]
				end
			end
		end
		ret
	end

	#
	#     display_time(workitem.dispatch_time)
	#         # => Sat Mar 1 20:29:44 2008 (1d16h18m)
	#
	#     display_time(workitem, :dispatch_time)
	#         # => Sat Mar 1 20:29:44 2008 (1d16h18m)
	#
	def display_time (object, accessor=nil)
		t = accessor ?  object.send(accessor) : object
		return "" unless t
		"#{t.ctime} (#{display_since(t)})"
	end

	#
	#     display_since(workitem, :dispatch_time)
	#         # => 1d16h18m
	#
	def display_since (object, accessor=nil)
		t = accessor ? object.send(accessor) : object
		return "" unless t
		d = Time.now - t
		Rufus::to_duration_string(d, :drop_seconds => false)
	end

	def object_path(obj)
		path = send "#{obj.class.to_s.downcase}_path", obj
	end

	def h_input_domain(f)
		fname=self.class.name+"."+__method__.to_s
		#LOG.info (fname){"admin_logged_in?=#{admin_logged_in?} DOMAIN_FOR_ALL=#{PlmServices.get_property(:DOMAIN_FOR_ALL)}"}
		ret=""
		if admin_logged_in? || PlmServices.get_property(:DOMAIN_FOR_ALL)==true
			ret = h_input_text(f ,:domain)
		end
		ret
	end

	def h_input_text(f ,field)
		ret = f.label field, t("label_#{field}")
		ret += f.text_field field
		ret
	end

	def h_attribut_trtd(obj, accessor)
		fname=self.class.name+"."+__method__.to_s
		final_obj=obj
		final_acc=accessor.to_s
		# recherche de l'objet final dans l'accesseur:
		# typesobject.name = typesoject
		# child.statusobject.name = statusobject
		#
		labacc=final_acc.to_s.tr('.','_')
		fields = final_acc.split(".")
		0.upto (fields.count-2) { |i|
			final_obj = final_obj.send(fields[i].to_s)
			final_acc = fields[i+1].to_s
		}
		ret="<tr>"
		ret+="<th>"
		ret+=t("label_"+labacc.to_s)
		ret+="</th>"
		ret+="<td>"
		begin
			vacc="v_"+final_acc.to_s
			#LOG.info (fname){"final_obj=#{final_obj} final_acc=#{final_acc} labacc=#{labacc}"}
			if final_obj.respond_to?(vacc)
			val=final_obj.send(vacc).to_s
			else
			val=final_obj.send(final_acc).to_s
			end
			ret+=val
		rescue Exception => e
			LOG.warn (fname){e}
			ret+="???"
		end
		ret+="</td>"
		ret+="</tr>"
		ret
	end

	#
	# build a set of strings separated by a comma
	# each part of the string is composed of the accessor applicated on the object
	def comma_string (objects, accessor=:name)
		objects.collect { |o|
			o.send(accessor)
		}.join(', ')
	end

	#
	# build a set of links separated by a comma
	# the label of each link is composed of the accessor (attribute of the object) applicated on the object and the translated accessor
	def comma_links (objects, accessor=:name)
		objects.collect { |o|
			name = o.send(accessor)
			met="#{accessor}_translate"
			if o.respond_to? met
				name_tr = o.send(met)
				name = "#{name}(#{name_tr})"
			end
			path = send "#{o.class.to_s.downcase}_path", o
			link_to(h(name), path)
		}.join(', ')
	end

	#
	# given a view, returns the link to the same view in another content type
	# (xml / json)
	#
	def as_x_href (format)

		href = [
			:protocol, :host, ':', :port,
			:request_uri, ".#{format}?plain=true"
		].inject('') do |s, elt|
			s << if elt.is_a?(String)
			elt
			elsif request.respond_to?(elt)
				request.send(elt).to_s
			else # shouldn't happen, so let's be verbose
			elt.inspect
			end
			s
		end
		href << "&#{request.query_string}" if request.query_string.length > 0
		href
	end

	# affiche ou edite les valeurs specifiques au type
	# argum obj l'objet
	# argum fonct la fonction demandee
	# - show: on les montre seulement
	# - edit: on peut les editer
	# - define: on les definit (dans typesobject seulement pour le moment)
	def h_type_values(obj, fonct)
		fname=self.class.name+"."+__method__.to_s
		#LOG.info (fname){"obj=#{obj} fonct=#{fonct}"}
		ret=""
		if !fonct.include?("new") && obj.respond_to?(:typesobject)
			unless obj.typesobject.nil?
				objfields = obj.typesobject.get_fields
				#LOG.info (fname){"fields=#{objfields} obj.type_values=#{obj.type_values}"}
				unless objfields.nil?
					case fonct
					when "edit", "account_edit"
						if obj.type_values.nil?
						obj.type_values=objfields
						end
					end
					ret+="<h1>"
					ret+=t(:legend_type_values, :type => t("typesobject_name_#{obj.typesobject.name}"))
					ret+="</h1>"
					#LOG.info (fname){"type_values=#{obj.type_values}"}
					unless obj.type_values.nil?
						ret+= h_render_fields(obj, fonct, "type_values")
					#options: all, position, none
					end
				else
					ret+="<h1>"
					ret+=t(:legend_type_values, :type =>t("typesobject_name_#{obj.typesobject.name}"))
					ret+="</h1>"
				end
			end
		end
		ret
	end

	def h_history_fields(obj, fonct)
		history_fields=obj.wi_fields
		puts "application_helper.h_history_fields:history_fields="+history_fields
		ret=""
		unless history_fields.nil?
			ret+="<fieldset><legend>"
			ret+=t(:legend_wi_fields)
			ret+="</legend>"
			ret+= h_render_fields(obj, fonct, "wi_fields")
			ret+="</fieldset>"
		else
			ret=t("history_no_fields")
		end
		#puts "******************** h_history_fields:ret="+ret
		ret
	end

	def h_workitem_fields(obj, fonct)
		fields=obj.field_hash
		#puts "application_helper.h_workitem_fields:fields=#{fields}"
		ret=""
		unless fields.nil?
			ret+="<h1>"
			ret+=t(:legend_wi_fields)
			ret+="</h1>"
			ret+= h_render_fields(obj, fonct, "field_hash", true)
		else
			ret=t("history_no_fields")
		end
		#puts "******************** h_history_fields:ret="+ret
		ret
	end

	def h_render_fields(obj, fonct, method, to_json=false)
		fname=self.class.name+"."+__method__.to_s
		fields = obj.send(method)
		form_id=h_form_html_id(obj, fonct)
		#LOG.info (fname){"obj=#{obj}, fonct=#{fonct}, method=#{method}, fields=#{fields}, form_id=#{form_id}"}
		unless fields.nil?
			if to_json
			fields=fields.to_json
			#LOG.info (fname){"fields_json=#{fields}"}
			end
			buttons="none"
			edit_key=false
			edit_value=false
			if fonct.include? "show"
				buttons="none"
			edit_key=false
			edit_value=false
			end
			if fonct.include? "edit"
				buttons="position"
			edit_key=false
			edit_value=true
			end
			if fonct.include? "define"
				buttons="all"
			edit_key=true
			edit_value=true
			end
			ret=render(
				:partial => "shared/form_json",
				:locals => {
					:fields => fields,
					:form_id => form_id,
					:textarea_name => "#{obj.model_name}[#{method}]",
					:options => {"buttons" => buttons, "edit_key" => edit_key, "edit_value" => edit_value }
				}
				)
		else
			ret=""
		end
		ret
	end

	# renvoi l'identifiant du formulaire en fonction de l'objet et de la fonction demandee
	def h_form_html_id(obj, fonct)
		"#{fonct}_#{obj.model_name}"
	end

	#
	# FLUO
	#
	def render_fluo (opts)

		tree = if d = opts[:definition]
			"<script src=\"/definitions/#{d.id}/tree.js?var=proc_tree\"></script>"
		elsif pr = opts[:process]
			"<script src=\"/processes/#{pr.wfid}/tree.js?var=proc_tree\"></script>"
		elsif i = opts[:wfid]
			"<script src=\"/processes/#{i}/tree.js?var=proc_tree\"></script>"
		elsif t = opts[:tree]
			"<script>var proc_tree = #{t.to_json};</script>"
		elsif t = opts[:tree_json]
			"<script>var proc_tree = #{t};</script>"
		else
			'<script>var proc_tree = null;</script>'
		end

		hl = if e = opts[:expid]
			"\nFluoCan.highlight('fluo', '#{e}');"
		else
			''
		end
		more="<a class=\"menu_bas\">#{t('label_more')}</a>"
		less="<a class=\"menu_bas\">#{t('label_less')}</a>"

		workitems = Array(opts[:workitems])

		%{
      <!-- fluo -->

      <script src="/javascripts/fluo-json.js"></script>
      <script src="/javascripts/fluo-can.js"></script>

      <script>
        var proc_tree = null;
          // initial default value (overriden by following scripts)
      </script>

      <div id='fluo_minor_toggle' style='cursor: pointer;'>
            <table><tr><td class='menu_bas'><div id='fluo_toggle'>#{more}</div></td></tr></table>
      </div>

      <a id='dataurl_link'>
        <canvas id="fluo" width="50" height="50"></canvas>
      </a>

      #{tree}

      <script>
        if (proc_tree) {

          FluoCan.renderFlow(
            'fluo', proc_tree, { 'workitems': #{workitems.inspect} });

          FluoCan.toggleMinor('fluo');
          FluoCan.crop('fluo');#{hl}

          var a = document.getElementById('dataurl_link');
          a.href = document.getElementById('fluo').toDataURL();

          var toggle = document.getElementById('fluo_toggle');
          toggle.onclick = function () {
            FluoCan.toggleMinor('fluo');
            FluoCan.crop('fluo');
            if (toggle.innerHTML == '#{more}') toggle.innerHTML = '#{less}'
            else toggle.innerHTML = '#{more}';
          };
        }
      </script>
        }
	end

	#
	# used to build links to things like "/workitems?wfid=xyz or"
	# /processes?workflow=cheeseburger_order
	#
	def link_to_slice (item, accessor, param_name=nil)
		v = h(item.send(accessor))
		link_to(v, (param_name || accessor) => v)
	end

	def get_model(model_name)
		begin
			ret=eval model_name.camelize
		rescue Exception => e
			LOG.warn("failed to find "+model_name+" : #{e}")
			ret=nil
		end
		ret
	end

	def h_workitems_links(workitem)
		fname=self.class.name+"."+__method__.to_s
		ret=""
		workitem.get_wi_links.each { |obj|
			LOG.debug (fname){"obj=#{obj}"}
			ret << h_explorer(obj[:typeobj])
		}.join(', ')
		ret
	end

end

