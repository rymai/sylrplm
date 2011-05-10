# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  # renvoie la valeur de l'attribut att sur current si
  # 1- current n'a pas le meme identifiant que previous
  # 2- que les valeurs de l'attribut sont differentes entre les 2objets
  # att peut etre un attribut "compose" tel que owner.login
  def h_if_differ(current, previous,  att)
    ret=get_val(current,att)
    unless previous.nil?
      if current.ident == previous.ident && ret == get_val(previous, att)
        ret= ""
      end
    end
    ret
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
    bloc<<"<a class='menu' onclick=\"return helpPopup('#{help}','#{href}');\" >#{title}</a><br />";
    bloc
  end

  def h_help_menu(name,link)
    bloc=""
    if(link!=nil && link.strip()!="")
      bloc<<"<a href='/help?help="+link+"'>"+h_img(name)+"</a>"
    end
  end

  # memorisation du click sur le help
  def tip_help()
    bloc=""
    bloc<<"<img class='help' id='tip_help' src='/images/help.png' onclick='return helpTip();'>"
    bloc
  end

  def show_help(key)
    txt=t(key)
    bloc=""
    bloc<<"<img class=\"help\" id=\"#{key}\"  src=\"/images/help.png\"
    onclick=\"return helpPopup('#{key}');\">"
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

  def form_simple_query_helper(url,objects)
    bloc=""
    bloc<<form_tag(url, :method=>:get)
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
    bloc << h_img_sub(:filter)
    bloc << "</td>"
    bloc << "</tr></table>"
    bloc
  end

  def icone(object)
    type=object.type.to_s+"_"+object.typesobject.name.to_s
    fic="images/"+type+".png"
    if !File.exists?(fic)
      type=object.type.to_s
      fic="images/"+type+".png"
    end
    "<img class='icone' src='"+fic+"' title='"+t("ctrl_"+type.downcase)+"'></img>"
  end

  def h_img(name)
    ret="<img class=\"icone\" src=\"/images/"+name.to_s+".png\" title='"
    ret<<t(name.to_s)
    ret<<"'></img>"
    ret.to_s
  end

  def h_img_tit(name,title)
    ret="<img class=\"icone\" src=\"/images/"+name.to_s+".png\" title='"
    ret<<title.to_s
    ret<<"'></img>"
  end

  def h_img_cut
    h_img("cut")
  end

  def h_img_destroy
    h_img("destroy")
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

  def h_destroy(obj)
    img=h_img_destroy
    link_to(img.to_s , obj, :confirm => t(:msg_confirm), :method => :delete)
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

  def h_sylrplm_tree
    bloc=""
    if (@tree || @tree_up)
      bloc << "<table class='menu_bas' >"
      bloc << "<tr>"
      bloc<< "<td><a class='menu_bas' href='#' onclick='hideTreeMenu();'>"+t("h_show_hide_tree")+"</a></td>"
      bloc << "</tr>"
      bloc << "</table>"
      bloc << "<div id='dtree'>"
      if (@tree)
        bloc <<@tree.to_s
      end
      if (@tree_up)
        bloc <<@tree_up.to_s
      end

      bloc << "</div>"

    end
    bloc
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

    Rufus::to_duration_string(d, :drop_seconds => true)
  end

  def comma_list (objects, accessor=:name)

    objects.collect { |o|
      name = o.send(accessor)
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
    else
      '<script>var proc_tree = null;</script>'
    end

    hl = if e = opts[:expid]
      "\nFluoCan.highlight('fluo', '#{e}');"
    else
      ''
    end
    more=t('label_more')
    less=t('label_less')
    workitems = Array(opts[:workitems])

    %{
      <!-- fluo -->

      <script src="/javascripts/fluo-json.js"></script>
      <script src="/javascripts/fluo-can.js"></script>

      <script>
        var proc_tree = null;
          // initial default value (overriden by following scripts)
      </script>

      <a id='dataurl_link'>
        <canvas id="fluo" width="50" height="50"></canvas>
      </a>
      <div  id='fluo_minor_toggle' style='cursor: pointer;'>
            <table class='menu_bas'><tr><td><div id='fluo_toggle'>#{more}</div></td></tr></table>
      </div>
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
  # used to build links to things like /workitems?wfid=xyz or
  # /processes?workflow=cheeseburger_order
  #
  def link_to_slice (item, accessor, param_name=nil)

    v = h(item.send(accessor))
    link_to(v, (param_name || accessor) => v)
  end

  def connected
    User.connected(session)
  end
end

