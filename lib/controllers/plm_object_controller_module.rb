module Controllers::PlmObjectControllerModule
  def self.included(base)
    base.extend(ClassMethods)
  end

  # methodes de classe
  module ClassMethods
    #  access_control [:create, :edit] => 'admin & !blacklist',
    #                 :update => '(admin | moderator) & !blacklist',
    #                 :list => '(admin | moderator | user) & !blacklist'
    def event_manager
      name=controller_class_name+".event_manager:"
      before_filter do |c|
        #syl
        role_title=""
        if c.access_context[:user]!=nil
          if c.access_context[:user].role!=nil
            role_title=c.access_context[:user].role.title
          end
        end
        puts name+"before: role_title="+role_title+" controller="+c.controller_name+" action="+c.action_name
      end
      after_filter do |c|
        #syl
        role_title=""
        if c.access_context[:user]!=nil
          if c.access_context[:user].role!=nil
            role_title=c.access_context[:user].role.title
          end
        end
        puts name+"after: role_title="+role_title+" controller="+c.controller_name+" action="+c.action_name
      end

    end

    def event_manager_before
      name=controller_class_name+".event_manager_before:"
      before_filter do |c|
        #syl
        role_title=""
        if c.access_context[:user]!=nil
          if c.access_context[:user].role!=nil
            role_title=c.access_context[:user].role.title
          end
        end
        puts name+"before: role_title="+role_title+" controller="+c.controller_name+" action="+c.action_name
      end

    end

    def event_manager_after
      name=controller_class_name+".event_manager_after:"
      puts name
      after_filter do |c|
        #syl
        role_title=""
        if c.access_context[:user]!=nil
          if c.access_context[:user].role!=nil
            role_title=c.access_context[:user].role.title
          end
        end
        puts name+"role_title="+role_title+" controller="+c.controller_name+" action="+c.action_name
      end
    end
  end # ClassMethods

  def object_exists
    name=controller_class_name+".object_exists"
    puts name+params.inspect
    begin
      obj=get_model(params).find(params[:id])
      puts name+obj.inspect
    rescue Exception => err
      if obj.nil?
        flash[:notice] = t(:ctrl_object_not_existing, :model=>get_model_type(params), :id=>params[:id], :error=>err)
        redirect_to(:action => "index")
      end
    end
#    if obj.nil?
#      flash[:notice] = t(:ctrl_record_error)
#      redirect_to(:action => "index")
#    end

  end

  def ctrl_revise(model)
    define_variables
    object = model.find(params[:id])
    previous_rev=object.revision
    @object=object.revise
    @types=Typesobject.get_types(object.class.name.downcase!)
    respond_to do |format|
      if(@object != nil)
        if @object.save
          puts object.class.name+'.revision apres save='+@object.id.to_s+":"+@object.revision;
          flash[:notice] = t(:ctrl_object_revised,:typeobj =>t(:ctrl_.to_s+@object.class.name.downcase!),:ident=>@object.ident,:previous_rev=>previous_rev,:revision=>@object.revision)
          format.html { redirect_to(@object) }
          format.xml  { head :ok }
        else
          format.html { render :action => "edit" }
          format.xml  { render :xml => object.errors, :status => :unprocessable_entity }
        end
      else
        @object = model.find(params[:id])
        flash[:notice] = t(:ctrl_object_not_revised,:typeobj =>t(:ctrl_.to_s+@object.class.name.downcase!),:ident=>@object.ident,:previous_rev=>previous_rev)
        #flash[:notice] = "Document cannot be revised from #{previous_rev} (not last revision or not frozen status ?)."
        format.html { redirect_to(@object) }
        format.xml  { head :ok }
      end
    end
  end

  #  def ctrl_promote(model, params, withMail=true)
  def ctrl_promote(object, withMail=true)
    puts "plm_object_controller.ctrl_promote:"+object.inspect+" "+withMail.to_s
    email_ok=true
    if withMail==true
      email_ok=PlmMailer.could_send(object.owner)
    end
    respond_to do |format|
      if email_ok==true
        current_rank=object.statusobject.name
        object.promote
        new_rank=object.statusobject.name
        current_rank!=new_rank
        if withMail==true
          email=nil
          validers=Role.get_validers
          if validers.length>0
            if object.save
              if object.could_validate?
                validersMail=PlmMailer.listUserMail(validers)
                email=PlmMailer.create_toValidate(object, current_user.email, @urlbase, validersMail)
              end
              if object.is_freeze
                validersMail=PlmMailer.listUserMail(validers, current_user)
                email=PlmMailer.create_validated(object, current_user.email, @urlbase, validersMail)
              end
              unless email.blank?
                email.set_content_type("text/html")
                PlmMailer.deliver(email)
              end
              flash[:notice] = t(:ctrl_object_promoted,:typeobj =>t(:ctrl_.to_s+object.class.name.downcase!),:ident=>object.ident,:current_rank=>current_rank,:new_rank=>new_rank,:validersMail=>validersMail)
              format.html { redirect_to(object) }
              format.xml  { head :ok }
            end
          else
            flash[:notice] = t(:ctrl_object_no_validers,:typeobj =>t(:ctrl_.to_s+object.class.name.downcase!),:ident=>object.ident,:current_rank=>current_rank,:new_rank=>new_rank)
            format.html { redirect_to(object) }
            format.xml  { head :ok }

          end
        else
          if object.save
            flash[:notice] = t(:ctrl_object_promoted,:typeobj =>t(:ctrl_.to_s+object.class.name.downcase!),:ident=>object.ident,:current_rank=>current_rank,:new_rank=>new_rank,:validersMail=>validersMail)
            format.html { redirect_to(object) }
            format.xml  { head :ok }
          else
            flash[:notice] = t(:ctrl_object_not_promoted,:typeobj =>t(:ctrl_.to_s+object.class.name.downcase!),:ident=>object.ident,:current_rank=>current_rank,:new_rank=>new_rank,:validersMail=>validersMail)
            format.html { render :action => "edit" }
            format.xml  { render :xml => object.errors, :status => :unprocessable_entity }
          end
        end
      else
        flash[:notice] = t(:ctrl_user_no_email,:user=>object.owner.login)
        format.html { render :action => "edit" }
        format.xml  { render :xml => object.errors, :status => :unprocessable_entity }
      end
    end
  end

  def ctrl_demote(model, withMail=true)
    object = model.find(params[:id])
    current_rank=object.statusobject.name
    object.demote
    new_rank=object.statusobject.name
    respond_to do |format|
      if current_rank!=new_rank
        if object.save
          if withMail==true
            askUserMail=object.owner.email
            email=nil
            validers=User.find_validers
            if object.could_validate?
              validersMail=PlmMailer.listUserMail(validers)
              email=PlmMailer.create_docToValidate(object, current_user.email, @urlbase, validersMail)
            end
            if object.frozen?
              validersMail=PlmMailer.listUserMail(validers, current_user)
              email=PlmMailer.create_docValidated(object, current_user.email, @urlbase, askUserMail, validersMail)
            end
            if(email!=nil)
              email.set_content_type("text/html")
              PlmMailer.deliver(email)
            end
          end
          flash[:notice] = t(:ctrl_object_demoted,:typeobj =>t(:ctrl_.to_s+object.class.name.downcase!),:ident=>object.ident,:current_rank=>current_rank,:new_rank=>new_rank,:validersMail=>validersMail)
          format.html { redirect_to(object) }
          format.xml  { head :ok }
        else
          flash[:notice] = t(:ctrl_object_not_demoted,:typeobj =>t(:ctrl_.to_s+object.class.name.downcase!),:ident=>object.ident,:current_rank=>current_rank,:new_rank=>new_rank)
          format.html { render :action => "edit" }
          format.xml  { render :xml => object.errors, :status => :unprocessable_entity }
        end
      else
        flash[:notice] = t(:ctrl_object_not_demoted,:typeobj =>t(:ctrl_.to_s+object.class.name.downcase!),:ident=>object.ident,:current_rank=>current_rank,:new_rank=>new_rank,:validersMail=>validersMail)
        format.html { redirect_to(object) }
        format.xml  { head :ok }
      end
    end
  end

  def ctrl_add_objects_from_favorites(object, child_plmtype)
    puts __FILE__+"."+__method__.to_s+":"+object.inspect+":"+child_plmtype.to_s
    relation = Relation.find(params[:relation][child_plmtype])
    plmtype=child_plmtype.to_s
    respond_to do |format|
      unless @favori.get(plmtype).nil?
        flash[:notice] = ""
        @favori.get(plmtype).each do |item|
          link_ = Link.create_new(object, item, relation)
          link=link_[:link]
          if(link!=nil)
            if(link.save)
              flash[:notice] += t(:ctrl_object_added,:typeobj =>t("ctrl_"+plmtype),:ident=>item.ident,:relation=>relation.ident,:msg=>link_[:msg])
              empty_favori_by_type(plmtype)
            else
              flash[:notice] += t(:ctrl_object_not_added,:typeobj =>t("ctrl_"+plmtype),:ident=>item.ident,:relation=>relation.ident,:msg=>link_[:msg])
            end
          else
            flash[:notice] += t(:ctrl_object_not_linked,:typeobj =>t("ctrl_"+plmtype),:ident=>item.ident,:relation=>relation.ident,:msg=>link_[:msg])
          end
        end
      else
        flash[:notice] = t(:ctrl_nothing_to_paste,:typeobj =>t("ctrl_"+plmtype))
      end
      puts __FILE__+"."+__method__.to_s+":notice="+flash[:notice]
      format.html { redirect_to(object) }
      format.xml  { head :ok }
    end
  end
    
  def tree_part(obj, link)
    if(obj!=nil)
      url={:controller => 'parts', :action => 'show', :id => "#{obj.id}"}
      link_to_remote= {
        :url => url,
        :update => "content",
        :base => self
      }
      link_to= url
      destroy_url=url_for(:controller => 'parts',
      :action => "remove_link",
      :id => link.id)
      cut_a='<a href="'+destroy_url+'">'+img_cut+'</a>'
      options={
        :label  => (link.relation.name||t(:ctrl_no_relation))+'-'+t(:ctrl_part)+":"+obj.ident+cut_a,
        :icon=>icone(obj),
        :icon_open=>icone(obj),
        #:title => obj.id.to_s,
        :title => obj.designation,
        :url=>url_for(url),
        :open => false
      }
      cnode = Node.new(options)
    else
      cnode=nil
    end
    cnode
  end

  def tree_project(obj, link)
    if(obj!=nil)
      url={:controller => 'projects', :action => 'show', :id => "#{obj.id}"}
      destroy_url=url_for(:controller => 'projects',
      :action => "remove_link",
      :id => link.id)
      cut_a='<a href="'+destroy_url+'">'+img_cut+'</a>'
      options={
        :label  => (link.relation.name||t(:ctrl_no_relation))+'-'+t(:ctrl_project)+":"+obj.ident+cut_a,
        :icon=>icone(obj),
        :icon_open=>icone(obj),
        :title => obj.designation,
        :open => false,
        :url=>url_for(url)
      }
      cnode = Node.new(options,nil)
    else
      cnode=nil
    end
    cnode
  end

  def follow_tree_part(node, part)
    puts 'follow_tree_part:'+part.inspect
    tree_forums(node,"part",part)
    tree_documents(node,"part",part)
    links=Link.find_childs(part,  "part")
    puts 'follow_tree_part:'+links.inspect
    links.each do |link|
      child=Part.find(link.child_id)
      url={:controller => 'parts', :action => 'show', :id => "#{child.id}"}
      destroy_url=url_for(:controller => 'parts',
      :action => "remove_link",
      :id => link.id)
      cut_a='<a href="'+destroy_url+'">'+img_cut+'</a>'
      options={
        :label  => (link.relation.name||t(:ctrl_no_relation))+'-'+t(:ctrl_part)+':'+child.ident+cut_a,
        :icon=>icone(child),
        :icon_open=>icone(child),
        :title => child.designation,
        :url=>url_for(url),
        :open => false
      }
      cnode = Node.new(options)
      node << cnode
      follow_tree_part(cnode, child)
    end
  end

  def follow_tree_up_part(node, part)
    follow_father("part",node,part)
    follow_father("project",node,part)
  end

  def follow_tree_up_document(node, doc)
    follow_father("document",node,doc)
    follow_father("part",node,doc)
    follow_father("project",node,doc)
    follow_father("customer",node,doc)
  end

  def follow_tree_customer(node, obj)
    tree_documents(node,"customer",obj)
    tree_forums(node,"customer",obj)
    links=Link.find_childs(obj,  "project")
    links.each do |link|
      child=Project.find(link.child_id)
      pnode=tree_project(child,link)
      node<<pnode
      follow_tree_project(pnode, child)
    end
  end

  def follow_tree_document(node, obj)
    tree_documents(node,"document",obj)
  end

  def follow_tree_project(node, obj)
    tree_users(node,"project",obj)
    tree_documents(node,"project",obj)
    tree_forums(node,"project",obj)
    links=Link.find_childs( obj,  "part")
    links.each do |link|
      child=Part.find(link.child_id)
      pnode=tree_part(child, link)
      node<<pnode
      follow_tree_part(pnode, child)
    end
  end

  def follow_tree_up_project(node, project)
    follow_father("customer",node,project)
  end

  def tree_documents(node, father_type, father)
    docs=Link.find_childs(father,  "document")
    docs.each do |link|
      d=Document.find(link.child_id)
      url={:controller => 'documents', :action => 'show', :id => "#{d.id}"}
      destroy_url=url_for(:controller => "links",
      :action => "remove_link",
      :id => "#{link.id}" )
      cut_a='<a href="'+destroy_url+'">'+img_cut+'</a>'
      options={
        :label => (link.relation.name||t(:ctrl_no_relation))+'-'+t(:ctrl_document)+':'+d.ident + cut_a,
        :icon=>icone(d),
        :icon_open=>icone(d),
        :title => d.designation,
        :open => false,
        :url=>url_for(url)
      }
      cnode = Node.new(options,nil)
      node<<cnode
    end
  end

  def tree_users(node, father_type, father)
    docs=Link.find_childs( father,  "user")
    docs.each do |link|
      d=User.find(link.child_id)
      url={:controller => 'users', :action => 'show', :id => "#{d.id}"}
      destroy_url=url_for(:controller => "links",
      :action => "remove_link",
      :id => "#{link.id}" )
      cut_a='<a href="'+destroy_url+'">'+img_cut+'</a>'
      options={
        :label => (link.relation.name||t(:ctrl_no_relation))+'-'+t(:ctrl_user)+':'+d.ident + cut_a,
        :icon=>icone(d),
        :icon_open=>icone(d),
        :title => d.designation,
        :open => false,
        :url=>url_for(url)
      }
      cnode = Node.new(options,nil)
      node<<cnode
    end
  end

  def tree_forums(node, father_type, father)
    docs = Link.find_childs( father,  "forum")
    docs.each do |link|
      d = Forum.find(link.child_id)
      url = { :controller => 'forums', :action => 'show', :id => "#{d.id}" }
      destroy_url = url_for(:controller => father.controller_name,
      :action => "remove_link",
      :id => "#{link.id}")
      if d.frozen?
        cut_a = ""
      else
        cut_a = '<a href="'+destroy_url+'">'+img_cut+'</a>'
      end
      options = {
        :label => (link.relation.name||t(:ctrl_no_relation))+'-'+t(:ctrl_forum)+':'+d.subject + cut_a,
        :icon => icone(d),
        :icon_open=>icone(d),
        :title => d.subject,
        :open => false,
        :url => url_for(url)
      }
      cnode = Node.new(options,nil)
      node << cnode
    end
  end

  def remove_link
    link = Link.remove(params[:id])
    respond_to do |format|
      format.html { redirect_to(session[:tree_object]) }
      format.xml  { head :ok }
    end
  end

  def ctrl_add_forum(object)
    type=object.model_name
    relation = Relation.find(params["relation_id"])
    error=false
    respond_to do |format|
      flash[:notice] = ""
      @forum=Forum.new(params[:forum])
      @forum.owner=@current_user
      if(@forum.save)
        item=ForumItem.create_new(@forum, params)
        if(item.save)
          link_=Link.create_new(object, @forum, relation)
          link=link_[:link]
          if(link!=nil)
            if(link.save)
               flash[:notice] += t(:ctrl_object_added,:typeobj =>t(:ctrl_forum),:ident=>@forum.subject,:relation=>relation,:msg=>t(link_[:msg]))
            else
               flash[:notice] += t(:ctrl_object_not_added,:typeobj =>t(:ctrl_forum),:ident=>@forum.subject,:relation=>relation,:msg=>t(link_[:msg]))
              @forum.destroy
              error=true
            end
          else
            msg=$!
            flash[:notice] += t(:ctrl_object_not_linked,:typeobj =>t(:ctrl_forum),:ident=>@forum.subject,:relation=>relation,:msg=>msg)
            @forum.destroy
            error=true
          end
        else
          msg=$!
          flash[:notice] += t(:ctrl_object_not_created, :typeobj =>t(:ctrl_forum_item),:msg=>msg)
          @forum.destroy
          error=true
        end
      else
         flash[:notice] += t(:ctrl_object_not_saved,:typeobj =>t(:ctrl_forum),:ident=>@forum.subject,:relation=>relation,:msg=>nil)
        error=true
      end
      if error==false
        format.html { redirect_to(object) }
      else
        @types=Typesobject.find_for("forum")
        @status= Statusobject.find_for("forum")
        @object=object
        format.html { render   :action => :new_forum, :id => object.id   }
      end
      format.xml  { head :ok }
    end
  end

  def get_nb_items(nb_items)
    unless nb_items.nil? || nb_items==""
      unless @current_user.nil?
        if nb_items!=@current_user.nb_items
          @current_user.update_attributes({:nb_items=>nb_items})
        end
      end
      nb_items
    else
      unless @current_user.nil?
        @current_user.nb_items
      else
        unless session[:nb_items].nil?
          session[:nb_items]
        else
          SYLRPLM::NB_ITEMS_PER_PAGE
        end
      end
    end
  end

  def add_favori
    #puts "PlmObjectControllerModule.add_favori:#{params.inspect}"
    model = get_model(params)
    obj = model.find(params[:id])
    @favori.add(obj)
  end

  def empty_favori_by_type(type=nil)
    @favori.reset(type)
  end

  def empty_favori
    puts "===PlmObjectControllerModule.empty_favori"+params.inspect
    empty_favori_by_type(get_model_type(params))
  end

  # enlever le 's' de fin
  # :controller=>parts devient part
  def get_model_type(params)
    name=self.class.name+"."+__method__.to_s+":"
    ret = case params[:controller]
      when "documents" then params[:controller].chop
      when "parts" then params[:controller].chop
      when "projects" then params[:controller].chop
      when "customers" then params[:controller].chop
      when "notifications" then params[:controller].chop
      when "users" then params[:controller].chop
    else params[:controller]
    end
    #puts name+params[:controller]+"="+ret
    ret
  end

  def get_controller_from_model_type(model_type)
    # ajouter le 's' de fin
    # part devient parts
    model_type+"s"
  end

  def get_model(params)
    name=self.class.name+"."+__method__.to_s+":"
    # parts devient Part
    #puts name+params.inspect
    eval get_model_type(params).capitalize
  end

  def get_model_name(model)
    # Part devient part
    model.class.name.downcase
  end

  def follow_father(model_name, node, obj)
    model=eval model_name.capitalize
    links=Link.find_fathers(get_model_name(obj), obj,  model_name)
    links.each do |link|
      f=model.find(link.father_id)
      url={:controller => get_controller_from_model_type(model_name), :action => 'show', :id => "#{f.id}"}
      options={
        :label  => (link.relation.name||t(:ctrl_no_relation))+'-'+t("ctrl_"+model_name)+':'+f.ident,
        :icon => icone(f),
        :icon_open=>icone(f),
        :title => f.designation,
        :url => url_for(url),
        :open => false
      }
      html_options = {
        :alt => "alt:"+f.ident
      }
      cnode = Node.new(options)
      node << cnode
    end
  end

  def icone(obj)
    unless obj.model_name.nil? || obj.typesobject.nil?
      ret="/images/"+obj.model_name.to_s+"_"+obj.typesobject.name+".png"
      unless File.exist?(ret)
        ret="/images/"+obj.model_name.to_s+".png"
        unless File.exist?("#{RAILS_ROOT}/public/"+ret)
         ret=""
        end
      end
    else
      ret=""
    end
    ret
  end

  def img(name)
    "<img class=\"icone\" src=\"../images/"+name+".png\"/>"
  end

  def img_destroy
    img("destroy")
  end

  def img_cut
    img("cut")
  end
    def get_themes(default)
    #renvoie la liste des themes
    dirname = "#{Rails.root}/public/stylesheets/*"
    ret = ""
    Dir[dirname].each do |dir|
      if File.directory?(dir)
        theme = File.basename(dir, '.*')
        if theme == default
          ret << "<option selected=\"selected\">#{theme}</option>"
        else
          ret << "<option>#{theme}</option>"
        end
      end
    end
    ret
  end

  def get_languages
    #renvoie la liste des langues
    dirname = "#{Rails.root}/config/locales/*.yml"
    ret = []
    Dir[dirname].each do |dir|
      lng = File.basename(dir, '.*')
      ret << [t("language_"+lng), lng]
    end
    #puts "application_controller.get_languages"+dirname+"="+ret.inspect
    ret
  end

  def get_html_options(lst, default, translate=false)
    ret=""
    lst.each do |item|
      if translate
        val=t(item[1])
      else
      val=item[1]
      end
      if item[0].to_s == default.to_s
        #puts "get_html_options:"+item.inspect+" = "+default.to_s
        ret << "<option value=\"#{item[0]}\" selected=\"selected\">#{val}</option>"
      else
        ret << "<option value=\"#{item[0]}\">#{val}</option>"
      end
    end
    #puts "application_controller.get_html_options:"+ret
    ret
  end

  def html_models_and_columns(default = nil)
    lst=[]
    Dir.new("#{RAILS_ROOT}/app/models").entries.each do |model|
      unless %w[. .. obsolete].include?(model)
        mdl = model.camelize.gsub('.rb', '')
        begin
          mdl.constantize.content_columns.each do |col|
            lst<<["#{mdl}.#{col.name}","#{mdl}.#{col.name}"] unless %w[created_at updated_at owner].include?(col.name)
          end
        rescue # do nothing
        end
      end
    end
    puts __FILE__+"."+__method__.to_s+":"+lst.inspect
    get_html_options(lst, default)
  end

  def build_tree(obj)   
    tree = Tree.new({:js_name=>"tree_down", :label => t(:ctrl_object_explorer, :typeobj => t("ctrl_"+obj.model_name)), :open => true })
    follow_tree(tree, obj)
    tree
  end
  
  def follow_tree(node, father)
    url = {:controller => father.controller_name, :action => :show, :id => "#{father.id}"}
    design = father.designation
    design.gsub!('\n\n','\n')
    design.gsub!('\n','<br/>')
    design.gsub!(10.chr,'<br/>')
    design.gsub!('\t','')
    design.gsub!("'"," ")
    design.gsub!('"',' ')
    options = {
        :label => t("ctrl_"+father.model_name)+':'+father.ident, 
        :icon=>icone(father),
        :icon_open=>icone(father),
        :title => design,
        :open => true,
        :url=>url_for(url)
    }
    cnode = Node.new(options,nil)
    node << cnode
    childs = father.method(father.model_name+"s").call
    #puts "follow_tree:"+childs.inspect
    childs.each do |child|
      follow_tree(cnode, child)
    end
    node
  end
  
end
