# = ApplicationHelper
# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
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
	#
	#
	# Renvoie la valeur de l'attribut att sur current si
	# 1- current n'a pas le meme identifiant que previous
	# 2- que les valeurs de l'attribut sont differentes entre les 2objets
	# att peut etre un attribut "compose" tel que owner.login
	def h_if_differ_old(current, previous,  att)
		ret=get_val(current,att)
		unless previous.nil?
			if current.ident == previous.ident && ret == get_val(previous, att)
				ret= ""
			end
		end
		ret
	end

	def h_if_differ_trop_general(current, previous)
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
		blk="obj="+obj.class.name+".find("+obj.id.to_s+")\nobj."+att
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

	def h_help_menu(name,link)
		bloc=""
		if(link!=nil && link.strip()!="")
			bloc<<"<a href='/help?help="+link+"'>"+h_img(name)+"</a>"
		end
	end

	def help_window
		ret = ""
		ret << "<a onclick=\"return helpWindow('help_#{params[:controller]}_#{params[:action]}');\">#{t(:help_window)}</a>"
		ret
	end

	def help_about
		ret = ""
		ret << "<a onclick=\"return helpWindow('help_about');\">#{t(:help_about)}</a>"
		ret
	end

	# memorisation du click sur le help
	def tip_help()
		bloc=""
		bloc<<"<img class='help' id='tip_help' src='/images/help.png' onclick='return helpTip();'>"
		bloc
	end

	def show_help(key, with_img = true)
		txt=t(key.to_s)
		bloc=""
		if with_img
			bloc<<"<img class=\"help\" id=\"#{key.to_s}\"  src=\"/images/help.png\"
    onclick=\"return helpPopup('#{key.to_s}');\" >"
		else
			bloc<<"<a href='/help?help="+key.to_s+"' onclick=\"return helpPopup('#{key.to_s}');\">"+txt+"</a>"
		end
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

	# pour compatibilite seulement
	def form_simple_query_helper(url, objects)
		h_form_simple_query(url, objects)
	end

	def h_form_simple_query(url, objects)
		bloc = ""
		bloc << form_tag(url, :method=>:get)
		bloc << h_simple_query(objects)
		bloc << hidden_field_tag("todo" , @myparams["todo"]) unless @myparams.nil?
		bloc << hidden_field_tag("html_ident" , @myparams["html_ident"]) unless @myparams.nil?
		bloc << "</form>"
		bloc
	end

	def h_simple_query(objects)
		#puts "h_simple_query:myparams=#{@myparams}"
		bloc = ""
		bloc << "<table><tr>"
		bloc << "<td>"
		bloc << t("query")
		bloc << text_field_tag(:query , value=objects[:query])
		bloc << "</td>"
		bloc << "<td>"
		bloc << t("nb_items_per_page")
		bloc << text_field_tag(:nb_items , value=objects[:nb_items], :size=>5)
		bloc << "</td>"
		bloc << "</td>"
		bloc << "<td>"
		bloc << select_tag("list_mode", options_for_select(get_list_modes, @myparams["list_mode"]) )
		bloc << "</td>"
		bloc << "<td>"
		bloc << h_img_sub(:filter)
		bloc << "</td>"

		bloc << "</tr></table>"
		bloc
	end

	def icone(object)
		type = "#{object.model_name}_#{object.typesobject.name}" unless object.typesobject.nil?
		fic="/images/#{type}.png"
		if !File.exists?("#{RAILS_ROOT}/public#{fic}")
			type="#{object.model_name}"
			fic="/images/#{type}.png"
		end
		mdl_name=t("ctrl_#{type.downcase}")
		ret = "<img class='icone' src='#{fic}' title='#{mdl_name}'></img>"
		unless @myparams[:list_mode].blank?
			if @myparams[:list_mode] != t(:list_mode_details)
				ret << h_thumbnails(object)
			end
		end
		ret
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

	def h_thumbnails(obj)
		ret=""
		if obj.respond_to? :thumbnails
			unless obj.thumbnails.nil?
				obj.thumbnails.each do |img|
					ret << "<img class='thumbnail' src=\"#{img.write_file_tmp}\"></img>"
				end
			end
		end
		ret
	end

	def h_img_path(name)
		"<img src=\"#{name}\"></img>"
	end

	def h_img(name, title=nil)
		if title.nil?
			title=t(File.basename(name.to_s))
		end
		"<img class=\"icone\" src=\"/images/#{name}.png\" title='#{title}'/>"
	end

	def h_img_btn(name)
		"<img class=\"btn\" src=\"/images/#{name}.png\" title='#{t(File.basename(name.to_s))}'/>"
	end

	def h_img_tit(name, title)
		"<img class=\"icone\" src=\"/images/#{name}.png\" title='#{title}'/>"
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
		#LOG.info (fname){"obj=#{obj}, method=#{method}"}
		ret=""
		unless obj.nil?
			if method.nil?
				method = "ident"
			end
			if obj.respond_to?(method)
			txt = obj.send(method)
			else
			txt = obj.ident
			end

			if txt.nil? || txt == ""
			txt = obj.to_s
			end
			title = t(name, :obj => obj)
			LOG.info (fname){"title=#{title}"}
			link_to( txt, obj, {:title => title } )
		end
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
		options = {
			:url => {:overwrite_params => {:sort => key, :page => nil}},
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

	def h_show_tree(obj)
		"don t use this function, prefer render shared/tree"
	end

	def h_show_tree_old(obj)
		bloc=""
		if ((@tree && @tree.size>0) || (@tree_up && @tree_up.size>0))
			#bloc << "<h1></h1>"
			#bloc << "<tr>"
			#form_for(obj, :url => {:id => obj.id, :action => "select_view" }) do |f|
			#	bloc <<	"<td>#{select("relation","view", options_from_collection_for_select( @views, :id, :name))}</td>"
			#	bloc << "<td>#{submit_tag t("select_view")}</td>"
			#end
			#bloc << "</tr>"
			bloc << "<div id='dtree'>"
			if (@tree && @tree.size>0)
				bloc << "<table class='menu_bas' >"
				bloc << "<tr>"
				bloc<< "<td><a class='menu_bas' href='#' onclick='openCloseAllTree(tree_down);'>"+t("h_open_close_all_tree")+"</a></td>"
				bloc << "</tr>"
				bloc << "</table>"
			bloc << @tree.to_s
			end
			if (@tree_up && @tree_up.size>0)
				bloc << "<table class='menu_bas' >"
				bloc << "<tr>"
				bloc<< "<td><a class='menu_bas' href='#' onclick='openCloseAllTree(tree_up);'>"+t("h_open_close_all_tree")+"</a></td>"
				bloc << "</tr>"
				bloc << "</table>"
			bloc << @tree_up.to_s
			end
			bloc << "</div>"
		end
		bloc
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

	def h_input_text(f ,field)
		if admin_logged_in? || ::SYLRPLM::DOMAIN_FOR_ALL==true
			ret=f.label field, t("label_#{field}")
		ret+=f.text_field field
		end
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
		#fields = final_acc.split(".")
		#0.upto (fields.count-2) { |i|
		#	final_obj = final_obj.send(fields[i].to_s)
		#	final_acc = fields[i+1].to_s
		#}
		labacc=final_acc.to_s.tr('.','_')
		ret="<tr>"
		ret+="<th>"
		ret+=t("label_"+labacc.to_s)
		ret+="</th>"
		ret+="<td>"
		begin
			vacc="v_"+final_acc.to_s
			LOG.info (fname){"final_obj=#{final_obj} final_acc=#{final_acc} labacc=#{labacc}"}
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

	def comma_links (objects, accessor=:name)
		objects.collect { |o|
			name = o.send(accessor)
			path = send "#{o.class.to_s.downcase}_path", o
			link_to(h(name), path)
		}.join(', ')
	end

	def comma_string (objects, accessor=:name)
		objects.collect { |o|
			o.send(accessor)
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
		#LOG.info (fname){"obj=#{obj}"}
		LOG.info (fname){"fonct=#{fonct}"}
		ret=""
		if obj.respond_to?(:typesobject)
			unless obj.typesobject.nil?
				unless obj.typesobject.fields.nil?
					LOG.info (fname){"fields=#{obj.typesobject.fields}"}
					case fonct
					when "show"
						buttons="none"
					when "edit"
						buttons="position"
						if obj.type_values.nil?
						obj.type_values=obj.typesobject.fields
						end
					when "define"
						buttons="all"
					else
					buttons="none"
					end
					unless obj.type_values.nil?
						ret+="<fieldset><legend>"
						ret+=t(:legend_type_values)
						ret+="</legend>"
						ret+= render(
		:partial => "shared/form_json",
		:locals => {
		:fields => obj.type_values,
		:form_id => h_form_html_id(obj, fonct),
		:textarea_name => obj.model_name+"[type_values]",
		:options => {"buttons" => buttons} }
		)
						#options: all, position, none
						ret+="</fieldset>"
					end
				end
			end
		end
		ret
	end

	# renvoi l'identifiant du formulaire en fonction de l'objet et de la fonction demandee
	def h_form_html_id(obj, fonct)
		fonct+"_"+obj.model_name
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

end

