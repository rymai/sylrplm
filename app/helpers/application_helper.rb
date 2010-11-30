# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  
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
  
  def form_simple_query_helper(url,query) 
    bloc=""
    bloc<<form_tag(url, :method=>:get)  
    bloc << "<p>"
    bloc << t("query") 
    bloc << text_field_tag(:query , value=query)
    bloc << h_img_sub(:filter) 
    bloc << "</p>" 
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
  def h_img_show
        h_img("explorer")
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
      :title => "Sort by this field",
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
  
 
  
end
