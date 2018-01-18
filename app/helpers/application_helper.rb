require 'digest/sha1'

# = ApplicationHelper
# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  #
  # select on type for update_type by Ajax
  #
  def h_edit_type_object(form, object, types)
    fname = "#{self.class.name}.#{__method__}"
    # LOG.debug(fname){"object=#{object.inspect}"}
    # LOG.debug(fname){"types=#{types} "}
    option_readonly = { readonly: object.column_readonly?(:typesobject_id) }
    if object.id.nil?
      option_onchange = nil
    else
      url = { controller: get_controller_from_model_type(object.modelname), action: 'update_type', id: object.id }
      # LOG.debug(fname){"url=#{url} "}
      with = "'object_type='+value"
      option_onchange = { onchange: remote_function(url: url, with: with) }
    end
    ret = ''
    ret += form.label(t('label_type'))
    ret += if option_onchange.nil?
      form.collection_select(:typesobject_id, types, :id, :name, option_readonly)
    else
      form.collection_select(:typesobject_id, types, :id, :name, option_readonly, option_onchange)
    end
    ret += '</br>'
    ret.html_safe unless ret.html_safe?
  end

  def h_edit_forobject_object(form, object, forobjects)
    fname = "#{self.class.name}.#{__method__}"
    LOG.debug(fname) { "object=#{object.inspect}" }
    LOG.debug(fname) { "forobjects=#{forobjects}" }
    option_readonly = { readonly: object.column_readonly?(:typesobject_id) }
    if object.id.nil?
      option_onchange = nil
    else
      url = { controller: get_controller_from_model_type(object.modelname), action: 'update_forobject', id: object.id }
      # LOG.debug(fname){"url=#{url} "}
      with = "'object_forobject='+value"
      option_onchange = { onchange: remote_function(url: url, with: with) }
    end
    ret = ''
    ret += form.label(t('label_object'))
    ret += if option_onchange.nil?
             form.select(:forobject, forobjects, option_readonly)
           else
             form.select(:forobject, forobjects, option_readonly, option_onchange)
           end
    ret += '</br>'
    ret.html_safe unless ret.html_safe?
  end

  def h_show_translate(item)
    " (#{item})"
  end

  def h_edit_lifecycle(a_form, a_object)
    render(
      partial: 'shared/lifecycle_edit',
      locals: { a_form: a_form, a_object: a_object }
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
      ret = value unless value.empty?
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
      ret = '' if current == previous
    end
    ret
  end

  def h_if_differ(current, _previous)
    current
  end

  # renvoie la valeur de l'attribut att sur l'objet
  # att peut etre un attribut "compose" tel que owner.login, d'ou l'utilisation de eval
  def get_val(obj, att)
    blk = "obj = #{obj.class.name}.find(#{obj.id})\nobj.#{att}"
    # puts "blk="+blk
    ret = eval blk
    ret
  end

  def h_count_objects(objects)
    num_begin = if objects[:page].nil?
                  0
                else
                  (objects[:page].to_i - 1)
                end
    num_begin *= objects[:nb_items].to_i
    num_begin += 1
    num_end = num_begin + objects[:recordset].length - 1
    t('count_objects', number_begin: num_begin, number_end: num_end, total: objects[:total])
  end

  def h_form_simple_query(url, objects, object_plm = nil)
    unless params[:filter_types].nil?
      url += "?filter_types=#{params[:filter_types]}"
    end
    render(
      partial: 'shared/form_simple_query',
      locals: { url: url, objects: objects, object_plm: object_plm }
    )
  end

  def h_thumbnails_objs(objs)
    objs[:recordset].each_with_object('') do |obj, ret|
      ret += "<span class='thumbnail'>"
      ret += h_explorer(obj, :ident)
      ret += icone(obj)
      ret += '</span>'
    end.html_safe
  end

  def h_img_path(name)
    "<img src=\"#{name}\"></img>".html_safe unless ret.html_safe?
  end

  def h_image(name, title = nil)
    title = t(File.basename(name.to_s)) if title.nil?
    h_img_base(name, title, 'image')
  end

  def h_img(name, title = nil)
    title = t(File.basename(name.to_s)) if title.nil?
    h_img_base(name, title, 'icone')
  end

  def h_img_btn(name)
    title = t(File.basename(name.to_s))
    h_img_base(name, title, 'btn')
  end

  def h_img_tit(name, title)
    h_img_base(name, title, 'icone')
  end

  def h_img_base(name, title, cls)
    ret = "<img class='#{cls}' src='/images/#{name}.png' title='#{title}'/>"
    ret.html_safe unless ret.html_safe?
  end

  def h_img_cut
    h_img('cut')
  end

  def h_img_destroy
    h_img('destroy')
  end

  def h_img_checkout
    h_img('img_checkout')
  end

  def h_img_checkin
    h_img('img_checkin')
  end

  def h_img_edit
    h_img('edit')
  end

  def h_img_edit_task
    h_img('edit_task')
  end

  def h_img_show
    h_img('explorer')
  end

  def h_img_launch
    h_img('launch')
  end

  def h_img_launchthis
    h_img('launchthis')
  end

  def h_img_revise
    h_img('revise')
  end

  def h_img_add_projects
    h_img('paste_projects')
  end

  def h_img_add_documents
    h_img('paste_documents')
  end

  def h_img_add_parts
    h_img('paste_parts')
  end

  def h_img_add_forum
    h_img('add_forum')
  end

  def h_img_list
    h_img('list')
  end

  def h_img_abort
    h_img('abort')
  end

  def h_img_edit_lifecycle
    h_img('edit_lifecycle')
  end

  def h_img_all
    h_img('all')
  end

  def h_img_pick
    h_img('pick')
  end

  def h_img_sub(name)
    image_submit_tag(name.to_s + '.png', title: t(name), class: 'submit')
  end

  def h_explorer(obj, method = nil)
    fname = "#{self.class.name}.#{__method__}"
    # LOG.info(fname){"obj=#{obj}, method=#{method}"}
    h_link_to('explorer_obj', obj, method)
  end

  def h_link_to(name, obj, method = nil)
    fname = "#{self.class.name}.#{__method__}"
    # LOG.info(fname){"name=#{name} obj=#{obj}, method=#{method}"}
    ret = ''
    begin
      unless obj.nil?
        method = 'ident' if method.nil?
        begin
          txt = obj.send(method.to_sym)
        rescue Exception => e
          txt = obj.ident
        end
        txt = obj.to_s if txt.blank?
        url = url_for(obj)
        unless params[:filter_types].nil?
          url += "?filter_types=#{params[:filter_types]}"
        end
        title = t(name, obj: obj)
        ret = link_to(txt, url, title: title)
        # LOG.info(fname){"name=#{name} obj=#{obj}, model=#{obj.modelname} , method=#{method} respond?=#{obj.respond_to?(method)} , txt=#{txt} , ret=#{ret}"}
      end
    rescue Exception => e
      LOG.error(fname) { "exception name=#{name}  method=#{method} error=#{e}" }
    end
    ret
  end

  def h_destroy(obj)
    button_to(t(:button_delete), obj, method: :delete, data: { confirm: t(:msg_confirm) })
  end

  def sort_td_class_helper(param)
    result = 'class="sortup"' if params[:sort] == param
    result = 'class="sortdown"' if params[:sort] == param.to_s + ' DESC'
    result
  end

  def sort_link_helper(text, param)
    fname = "#{self.class.name}.#{__method__}"
    key = param
    key += ' DESC' if params[:sort] == param
    #
    # DEPRECATION WARNING: The :overwrite_params option is deprecated. Specify all the necessary parameters instead.
    # old url = {:overwrite_params => {:sort => key, :page => nil}}
    # TODO ajouter le refresh: :onclick=>"window.location.reload()"
    url = params.merge(sort: key, page: nil)
    options = {
      url: url,
      update: 'table',
      before: "Element.show('spinner')",
      success: "Element.hide('spinner')",
      remote: false
    }
    html_options = {
      title: t('h_sort_by_field'),
      href: url_for(action: 'index', params: params.merge(sort: key, page: nil)),
      onclick: 'window.location.reload(false)'
    }
    LOG.debug(fname) { "sort_link_helper: text=#{text}" }
    LOG.debug(fname) { "sort_link_helper: options=#{options}" }
    LOG.debug(fname) { "sort_link_helper: html_options=#{html_options}" }
    link_to(text, options, html_options)
  end

  #
  # translate the second part of the message (after ":")
  # => send the first part as a translate variable
  # exemple : notifications.send_notifications send "#{user.login}:#{msg}", msg could be nothing_to_notify,mail_delivered or mail_not_created
  def h_tr_messag(msg)
    fname = "#{self.class.name}.#{__method__}"
    ret = ''
    unless msg.blank?
      msg.split(',').each do |u|
        # LOG.info(fname){"part of message=#{u}"}
        fields = u.split(':')
        ret += ',' unless ret.blank?
        ret += if fields.count > 1
                 t(fields[1], var: fields[0])
               else
                 fields[0]
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
  def display_time(object, accessor = nil)
    t = accessor ? object.send(accessor) : object
    return '' unless t
    "#{t.ctime} (#{display_since(t)})"
  end

  #
  #     display_since(workitem, :dispatch_time)
  #         # => 1d16h18m
  #
  def display_since(object, accessor = nil)
    return ''
    # TODO
    t = accessor ? object.send(accessor) : object
    return '' unless t
    d = Time.now - t
    Rufus.to_duration_string(d, drop_seconds: false)
  end

  def object_path(obj)
    path = send "#{obj.class.to_s.downcase}_path", obj
  end

  def h_input_domain(f)
    fname = "#{self.class.name}.#{__method__}"
    # LOG.info(fname){"admin_logged_in?=#{admin_logged_in?} DOMAIN_FOR_ALL=#{PlmServices.get_property(:DOMAIN_FOR_ALL)}"}
    ret = ''
    if admin_logged_in? || PlmServices.get_property(:DOMAIN_FOR_ALL) == true
      ret = h_input_text(f, :domain)
    end
    ret
  end

  def h_input_text(f, field)
    ret = f.label field, t("label_#{field}")
    ret += f.text_field field
    ret
  end

  def h_attribut_trtd(obj, accessor)
    fname = "#{self.class.name}.#{__method__}"
    final_obj = obj
    final_acc = accessor.to_s
    # recherche de l'objet final dans l'accesseur:
    # typesobject.name = typesoject
    # child.statusobject.name = statusobject
    #
    labacc = final_acc.to_s.tr('.', '_')
    fields = final_acc.split('.')
    0.upto (fields.count - 2) do |i|
      final_obj = final_obj.send(fields[i].to_s)
      final_acc = fields[i + 1].to_s
    end
    ret = '<tr>'
    ret += '<th>'
    ret += t('label_' + labacc.to_s)
    ret += '</th>'
    ret += '<td>'
    begin
      vacc = 'v_' + final_acc.to_s
      # LOG.info(fname){"final_obj=#{final_obj} final_acc=#{final_acc} labacc=#{labacc}"}
      val = if final_obj.respond_to?(vacc)
              final_obj.send(vacc).to_s
            else
              final_obj.send(final_acc).to_s
            end
      ret += val
    rescue Exception => e
      LOG.warn(fname) { e }
      ret += '???'
    end
    ret += '</td>'
    ret += '</tr>'
    ret.html_safe unless ret.html_safe?
  end

  #
  # build a set of links separated by a comma
  # the label of each link is composed of the accessor (attribute of the object) applicated on the object and the translated accessor
  def comma_links(objects, accessor = :name)
    objects.collect do |o|
      name = o.send(accessor)
      met = "#{accessor}_translate"
      if o.respond_to? met
        name_tr = o.send(met)
        name = "#{name}(#{name_tr})"
      end
      path = send "#{o.class.to_s.downcase}_path", o
      link_to(h(name), path)
    end.join(', ').html_safe
  end

  #
  # given a view, returns the link to the same view in another content type
  # (xml / json)
  #
  def as_x_href(format)
    href = [
      :protocol, :host, ':', :port,
      :request_uri, ".#{format}?plain=true"
    ].each_with_object('') do |elt, s|
      s += if elt.is_a?(String)
             elt
           elsif request.respond_to?(elt)
             request.send(elt).to_s
          else # shouldn't happen, so let's be verbose
            elt.inspect
          end
    end
    href << "&#{request.query_string}" unless request.query_string.empty?
    href
  end

  # affiche ou edite les valeurs specifiques au type
  # argum obj l'objet
  # argum fonct la fonction demandee
  # - show: on les montre seulement
  # - edit: on peut les editer
  # - define: on les definit (dans typesobject seulement pour le moment)
  def h_type_values(obj, fonct)
    fname = "#{self.class.name}.#{__method__}"
    # LOG.info(fname){"obj=#{obj} fonct=#{fonct}"}
    ret = ''
    if !fonct.include?('new') && obj.respond_to?(:typesobject)
      unless obj.typesobject.nil?
        objfields = obj.typesobject.get_fields
        LOG.info(fname) { "fields=#{objfields} obj.type_values=#{obj.type_values}" }
        if objfields.nil?
          ret += '<h1>'
          ret += t(:legend_type_values, type: t("typesobject_name_#{obj.typesobject.name}"))
          ret += '</h1>'
        else
          case fonct
          when 'edit', 'account_edit'
            obj.type_values = objfields if obj.type_values.nil?
          end
          ret += '<h1>'
          ret += t(:legend_type_values, type: t("typesobject_name_#{obj.typesobject.name}"))
          ret += '</h1>'
          # LOG.info(fname){"type_values=#{obj.type_values}"}
          unless obj.type_values.nil?
            f = h_render_fields(obj, fonct, 'type_values')
            ret += f unless f.nil?
            # options: all, position, none
          end
        end
      end
    end
    ret.html_safe unless ret.html_safe?
  end

  def h_workitem_fields(obj, fonct)
    fname = "#{self.class.name}.#{__method__}"
    fields = obj.fields
    # puts "application_helper.h_workitem_fields:fields=#{fields}"
    ret = ''
    if fields.nil?
      ret = t('history_no_fields')
    else
      ret += '<h1>'
      ret += t(:legend_fields)
      ret += '</h1>'
      hrf = h_render_fields(obj, fonct, 'fields', true)
      LOG.info(fname) { "hrf apres h_render_fields=#{hrf.length}" }
      ret += hrf.to_s unless hrf.nil?
    end
    # puts "******************** h_history_fields:ret="+ret
    ret.html_safe
  end

  def h_render_fields(obj, fonct, method, to_json = false)
    fname = "#{self.class.name}.#{__method__}"
    fields = obj.send(method)
    LOG.debug(fname) { "fields=#{fields}" }
    form_id = h_form_html_id(obj, fonct)
    LOG.info(fname) { "h_render_fields: obj=#{obj}, fonct=#{fonct}, method=#{method}, form_id=#{form_id}" }
    if fields.nil?
      ret = ''
    else
      if to_json
        fields = fields.to_json
        # LOG.info(fname){">>>>fields_json=#{fields}"}
      end
      buttons = 'none'
      edit_key = false
      edit_value = false
      if fonct.include? 'show'
        buttons = 'none'
        edit_key = false
        edit_value = false
      end
      if fonct.include? 'edit'
        buttons = 'position'
        edit_key = false
        edit_value = true
      end
      if fonct.include? 'define'
        buttons = 'all'
        edit_key = true
        edit_value = true
      end
      options = "{\"buttons\" : \"#{buttons}\", \"edit_key\" : \"#{edit_key}\", \"edit_value\" : \"#{edit_value}\"}"
      LOG.info(fname) { ">>>>options=#{options}" }
      ret = render(
        partial: 'shared/form_json',
        locals: {
          fields: fields,
          form_id: form_id,
          textarea_name: "#{obj.modelname}[#{method}]",
          options: options
        }
      )
    end
    LOG.info(fname) { "h_render_fields: obj=#{obj}, fonct=#{fonct}, method=#{method} " }
    LOG.info(fname) { "h_render_fields: ret=#{ret.length}" }
    ret.html_safe
  end

  # renvoi l'identifiant du formulaire en fonction de l'objet et de la fonction demandee
  def h_form_html_id(obj, fonct)
    "#{fonct}_#{obj.modelname}"
  end

  def get_tree_definition(definition_id)
    fname = "#{self.class.name}.#{__method__}"
    LOG.debug(fname) { "definition_id=#{definition_id} " }
    definition = Definition.find(definition_id)
    var = 'proc_tree'
    tree_json = definition.tree_json
    LOG.debug(fname) { "tree=#{tree_json} " }
    render(text: "var #{var} = #{tree_json};", content_type: 'text/javascript')
  end

  def get_tree_process(process_id)
    fname = "#{self.class.name}.#{__method__}"
    LOG.debug(fname) { "begin:params=#{params}" }
    PlmServices.ruote_init if RuoteKit.engine.nil?
    process = RuoteKit.engine.process(process_id)
    var = 'proc_tree'
    if process.nil?
      opts = {}
      opts[:page] = nil
      opts[:conditions] = "wfid = '" + params[:id] + "' and event = 'proceeded'" # TODO
      # puts fname+" opts="+opts.inspect
      # history = Ruote::Sylrplm::HistoryEntry.paginate(opts)
      # TODO render_text = "var #{var} = #{history.last.tree};"
    else
      render_text = "var #{var} = #{process.current_tree.to_json};"
    end
    LOG.info(fname) { "render_text=#{render_text}" }
    render(text: render_text, content_type: 'text/javascript')
  end

  #
  # FLUO
  #
  def render_fluo(opts)
    fname = "#{self.class.name}.#{__method__}"
    LOG.debug(fname) { "opts=#{opts} " }
    tree = if d = opts[:definition]
             # "<script src=\"/definitions/#{d.id}/tree.js?var=proc_tree\"></script>"
             "<script>#{get_tree_definition(d.id)}</script>"
           elsif pr = opts[:process]
             # "<script src=\"/processes/#{pr.wfid}/tree.js?var=proc_tree\"></script>"
             "<script>#{get_tree_process(pr.wfid)}</script>"
           elsif i = opts[:wfid]
             # "<script src=\"/processes/#{i}/tree.js?var=proc_tree\"></script>"
             "<script>#{get_tree_process(i)}</script>"
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
    more = "<a class=\"menu_toolbar\">#{t('label_more')}</a>"
    less = "<a class=\"menu_toolbar\">#{t('label_less')}</a>"
    if opts[:process]
      workitems = opts[:workitems]
    else
      workitems = []
      opts[:workitems].each do |wi|
        workitems << PlmServices.to_dots(wi)
      end
    end
    %{
      <!-- fluo -->
      <script src="/javascripts/fluo-json.js"></script>
      <script src="/javascripts/fluo-can.js"></script>
      <script>
        var proc_tree = null;
          // initial default value (overriden by following scripts)
      </script>
      <div id='fluo_minor_toggle' style='cursor: pointer;'>
            <table><tr><td class='menu_toolbar'><div id='fluo_toggle'>#{more}</div></td></tr></table>
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
        }.html_safe
	end

	#
	# used to build links to things like "/workitems?wfid=xyz or"
	# /processes?workflow=cheeseburger_order
	#
	def link_to_slice (item, accessor, param_name=nil)
		v = h(item.send(accessor))
		link_to(v, (param_name || accessor) => v)
	end

	def get_model(modelname)
		begin
			ret=eval modelname.camelize
		rescue Exception => e
			LOG.warn("failed to find "+modelname+" : #{e}")
			ret=nil
		end
		ret
	end

	def h_workitems_links(workitem)
		fname="#{self.class.name}.#{__method__}"
		ret=""
		workitem.get_wi_links.each { |obj|
			LOG.debug(fname){"obj=#{obj}"}
			ret << h_explorer(obj[:typeobj])
		}.join(', ')
		ret.html_safe unless ret.html_safe?
	end

	def h_show_a(link)
		show_url={:controller => link.child.controller_name,
			:action => 'show',
			:id => "#{link.child.id}"}
		show_a="<a href=\"#{url_for(show_url)}\" title=\"#{link.child.tooltip}\">#{link.child.label}</a>"
		show_a.html_safe unless show_a.html_safe?
	end

	def h_edit_link_a(link)
		rel_name="relation_#{link.relation.name}"
		tr_rel_name=t(rel_name).gsub!("'"," ")
		##quelquefois on perd la traduction !!!!
		tr_rel_name="#{link.relation.name}" if tr_rel_name.blank?
		link_values = link.type_values.gsub('\\','').gsub('"','') unless link.type_values.nil?
		img_rel="<img class=\"icone\" src=\"#{icone_fic(link)}\" title=\"#{clean_text_for_tree(link.tooltip)}\" />"
		edit_link_url = url_for(:controller => 'links',
		              :action => "edit_in_tree",
		              :id => link.id,
		              :object_model => link.father.modelname,
		              :object_id => link.father.id,
		              :root_model => "",
		              :root_id => "")
		edit_link_a = "<a href=\"#{edit_link_url}\" title=\"#{link_values}\">#{img_rel}#{tr_rel_name}</a>"
		edit_link_a.html_safe  unless edit_link_a.html_safe?
	end

	def h_remove_link(link)
		remove_link_url = url_for(:controller => 'links',
              :action => "remove_link",
              :id => link.id,
              :object_model => link.father.modelname,
              :object_id => link.father.id)
		remove_link_a = "<a href=\"#{remove_link_url}\">#{img_cut}</a>"
		remove_link_a.html_safe unless remove_link_a.html_safe?
	end

	def h_text_editor(form, object, attribut)
		attribut=attribut.to_s
		ret=""
		ret << form.text_area(attribut , :rows => 10, :readonly => object.column_readonly?(attribut))
		ret << "<script>CKEDITOR.replace( \"#{object.modelname}_description\");</script>"
		ret.html_safe unless ret.html_safe?
	end

	def truncate_words(text, len = 5, end_string = " ...")
		return if text.blank?
		words = text.split()
		words[0..(len-1)].join(' ') + (words.length > len ? end_string : '')
	end

	:private

	# Displays object errors
	def form_errors_for(plm_object=nil)
		fname="#{self.class.name}.#{__method__}"
		#LOG.debug(fname){"plm_object=#{plm_object}"}
		unless plm_object.blank?
			errors=plm_object.errors
			err_msg=[]
			if(errors.is_a?(Array))
				errors.each do |err|
					if(err.is_a?(String))
					err_msg<<err
					else
						if err.respond_to? :message
						err_msg << err.message
						else
						err_msg<<err
						end
					end
				end
			else
				plm_object.errors.full_messages.each do |message|
					err_msg << message
				end
			end
			LOG.debug(fname){"errors=#{err_msg}"}
		end
		render(:partial=>'shared/form_errors', :locals=>{:err_msg => err_msg}) unless plm_object.blank?
	end

  end

  #
  # used to build links to things like "/workitems?wfid=xyz or"
  # /processes?workflow=cheeseburger_order
  #
  def link_to_slice(item, accessor, param_name = nil)
    v = h(item.send(accessor))
    link_to(v, (param_name || accessor) => v)
  end

  def get_model(modelname)
    begin
      ret = eval modelname.camelize
    rescue Exception => e
      LOG.warn('failed to find ' + modelname + " : #{e}")
      ret = nil
    end
    ret
  end

  def h_workitems_links(workitem)
    fname = "#{self.class.name}.#{__method__}"
    ret = ''
    workitem.get_wi_links.each do |obj|
      LOG.debug(fname) { "obj=#{obj}" }
      ret << h_explorer(obj[:typeobj])
    end.join(', ')
    ret.html_safe unless ret.html_safe?
  end

  def h_show_a(link)
    show_url = { controller: link.child.controller_name,
                 action: 'show',
                 id: link.child.id.to_s }
    show_a = "<a href=\"#{url_for(show_url)}\" title=\"#{link.child.tooltip}\">#{link.child.label}</a>"
    show_a.html_safe unless show_a.html_safe?
  end

  def h_edit_link_a(link)
    rel_name = "relation_#{link.relation.name}"
    tr_rel_name = t(rel_name).tr!("'", ' ')
    # #quelquefois on perd la traduction !!!!
    tr_rel_name = link.relation.name.to_s if tr_rel_name.blank?
    link_values = link.type_values.delete('\\').delete('"') unless link.type_values.nil?
    img_rel = "<img class=\"icone\" src=\"#{icone_fic(link)}\" title=\"#{clean_text_for_tree(link.tooltip)}\" />"
    edit_link_url = url_for(controller: 'links',
                            action: 'edit_in_tree',
                            id: link.id,
                            object_model: link.father.modelname,
                            object_id: link.father.id,
                            root_model: '',
                            root_id: '')
    edit_link_a = "<a href=\"#{edit_link_url}\" title=\"#{link_values}\">#{img_rel}#{tr_rel_name}</a>"
    edit_link_a.html_safe unless edit_link_a.html_safe?
  end

  def h_remove_link(link)
    remove_link_url = url_for(controller: 'links',
                              action: 'remove_link',
                              id: link.id,
                              object_model: link.father.modelname,
                              object_id: link.father.id)
    remove_link_a = "<a href=\"#{remove_link_url}\">#{img_cut}</a>"
    remove_link_a.html_safe unless remove_link_a.html_safe?
  end

  def h_text_editor(form, object, attribut)
    attribut = attribut.to_s
    ret = ''
    ret << form.text_area(attribut, rows: 10, readonly: object.column_readonly?(attribut))
    ret << "<script>CKEDITOR.replace( \"#{object.modelname}_description\");</script>"
    ret.html_safe unless ret.html_safe?
  end

  def truncate_words(text, len = 5, end_string = ' ...')
    return if text.blank?
    words = text.split
    words[0..(len - 1)].join(' ') + (words.length > len ? end_string : '')
  end

  :private

  # Displays object errors
  def form_errors_for(plm_object = nil)
    fname = "#{self.class.name}.#{__method__}"
    LOG.debug(fname) { "plm_object=#{plm_object}" }
    unless plm_object.blank?
      errors = plm_object.errors
      err_msg = []
      if errors.is_a?(Array)
        errors.each do |err|
          err_msg << if err.is_a?(String)
                       err
                     else
                       err_msg << if err.respond_to? :message
                                    err.message
                                  else
                                    err
                                  end
                     end
        end
      else
        plm_object.errors.full_messages.each do |message|
          err_msg << message
        end
      end
      LOG.debug(fname) { "errors=#{err_msg}" }
    end
    render(partial: 'shared/form_errors', locals: { err_msg: err_msg }) unless plm_object.blank?
  end


