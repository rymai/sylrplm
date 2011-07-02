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
              if object.is_to_validate
                validersMail=PlmMailer.listUserMail(validers)
                email=PlmMailer.create_toValidate(object, @current_usermail, @urlbase, validersMail)
              end
              if object.is_freeze
                validersMail=PlmMailer.listUserMail(validers,@current_user)
                email=PlmMailer.create_validated(object, @current_usermail, @urlbase, validersMail)
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
            if object.is_to_validate
              validersMail=PlmMailer.listUserMail(validers)
              email=PlmMailer.create_docToValidate(object, @current_usermail, @urlbase, validersMail)
            end
            if object.frozen?
              validersMail=PlmMailer.listUserMail(validers,@current_user)
              email=PlmMailer.create_docValidated(object, @current_usermail, @urlbase, askUserMail, validersMail)
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

  def tree_part(obj, link,ctrl)
    if(obj!=nil)
      url={:controller => 'parts', :action => 'show', :id => "#{obj.id}"}
      link_to_remote= {
        :url => url,
        :update => "content",
        :base => self
      }
      link_to= url
      destroy_url=url_for(:controller => ctrl.controller_name,
      :action => "remove_link",
      :id => link.id)
      cut_a='<a href="'+destroy_url+'">'+img_cut+'</a>'
      options={
        :label  => (link.name||t(:ctrl_no_relation))+'-'+t(:ctrl_part)+":"+obj.ident+cut_a,
        :icon=>icone(obj),
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

  def tree_project(obj, link,ctrl)
    if(obj!=nil)
      url={:controller => 'projects', :action => 'show', :id => "#{obj.id}"}
      destroy_url=url_for(:controller => ctrl.controller_name,
      :action => "remove_link",
      :id => link.id)
      cut_a='<a href="'+destroy_url+'">'+img_cut+'</a>'
      options={
        :label  => (link.name||t(:ctrl_no_relation))+'-'+t(:ctrl_project)+":"+obj.ident+cut_a,
        :icon=>icone(obj),
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

  def follow_tree_part(node, part,ctrl)
    tree_forums(node,"part",part,ctrl)
    tree_documents(node,"part",part)
    links=Link.find_childs("part", part,  "part")
    links.each do |link|
      child=Part.find(link.child_id)
      url={:controller => 'parts', :action => 'show', :id => "#{child.id}"}
      destroy_url=url_for(:controller => ctrl.controller_name,
      :action => "remove_link",
      :id => link.id)
      cut_a='<a href="'+destroy_url+'">'+img_cut+'</a>'
      options={
        :label  => (link.name||t(:ctrl_no_relation))+'-'+t(:ctrl_part)+':'+child.ident+cut_a,
        :icon=>icone(child),
        :icon_open=>icone(child),
        :title => child.designation,
        :url=>url_for(url),
        :open => false
      }
      cnode = Node.new(options)
      node << cnode
      follow_tree_part(cnode, child,ctrl)
    end
  end

  def follow_tree_up_part(node, part,ctrl)
    follow_father("part",node,part)
    follow_father("project",node,part)
  end

  def follow_tree_up_document(node, doc,ctrl)
    follow_father("document",node,doc)
    follow_father("part",node,doc)
    follow_father("project",node,doc)
    follow_father("customer",node,doc)
  end

  def follow_tree_customer(node, obj,ctrl)
    tree_documents(node,"customer",obj,ctrl)
    tree_forums(node,"customer",obj,ctrl)
    links=Link.find_childs("customer", obj,  "project")
    links.each do |link|
      child=Project.find(link.child_id)
      pnode=tree_project(child,link,ctrl)
      node<<pnode
      follow_tree_project(pnode, child,ctrl)
    end
  end

  def follow_tree_document(node, obj,ctrl)
    tree_documents(node,"document",obj)
  end

  def follow_tree_project(node, obj,ctrl)
    tree_users(node,"project",obj)
    tree_documents(node,"project",obj)
    tree_forums(node,"project",obj,ctrl)
    links=Link.find_childs("project", obj,  "part")
    links.each do |link|
      child=Part.find(link.child_id)
      pnode=tree_part(child, link,ctrl)
      node<<pnode
      follow_tree_part(pnode, child,ctrl)
    end
  end

  def follow_tree_up_project(node, project,ctrl)
    follow_father("customer",node,project)
  end

  def tree_documents(node, father_type, father)
    docs=Link.find_childs(father_type, father,  "document")
    docs.each do |link|
      d=Document.find(link.child_id)
      url={:controller => 'documents', :action => 'show', :id => "#{d.id}"}
      destroy_url=url_for(:controller => "links",
      :action => "remove_link",
      :id => "#{link.id}" )
      cut_a='<a href="'+destroy_url+'">'+img_cut+'</a>'
      options={
        :label => (link.name||t(:ctrl_no_relation))+'-'+t(:ctrl_document)+':'+d.ident + cut_a,
        :icon=>icone(d),
        #:icon_open=>icone(d),
        :title => d.designation,
        :open => false,
        :url=>url_for(url)
      }
      cnode = Node.new(options,nil)
      node<<cnode
    end
  end

  def tree_users(node, father_type, father)
    docs=Link.find_childs(father_type, father,  "user")
    docs.each do |link|
      d=User.find(link.child_id)
      url={:controller => 'users', :action => 'show', :id => "#{d.id}"}
      destroy_url=url_for(:controller => "links",
      :action => "remove_link",
      :id => "#{link.id}" )
      cut_a='<a href="'+destroy_url+'">'+img_cut+'</a>'
      options={
        :label => (link.name||t(:ctrl_no_relation))+'-'+t(:ctrl_user)+':'+d.ident + cut_a,
        #:icon=>icone(d),
        #:icon_open=>icone(d),
        :title => d.designation,
        :open => false,
        :url=>url_for(url)
      }
      cnode = Node.new(options,nil)
      node<<cnode
    end
  end

  def tree_forums(node, father_type, father,ctrl)
    docs = Link.find_childs(father_type.to_s, father,  "forum")
    docs.each do |link|
      d = Forum.find(link.child_id)
      url = { :controller => 'forums', :action => 'show', :id => "#{d.id}" }
      destroy_url = url_for(:controller => ctrl.controller_name,
      :action => "remove_link",
      :id => "#{link.id}")
      if d.frozen?
        cut_a = ""
      else
        cut_a = '<a href="'+destroy_url+'">'+img_cut+'</a>'
      end
      options = {
        :label => (link.name||t(:ctrl_no_relation))+'-'+t(:ctrl_forum)+':'+d.subject + cut_a,
        :icon => icone(d),
        #:icon_open=>icone(d),
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
      #flash[:notice] = t(:ctrl_nothing_to_paste,:typeobj =>t(:ctrl_document))
      format.html { redirect_to(session[:tree_object]) }
      format.xml  { head :ok }
    end
  end

  def ctrl_add_forum(object,type)
    relation="forum"
    error=false
    respond_to do |format|
      flash[:notice] = ""
      @forum=Forum.new(params[:forum])
      @forum.owner=@current_user
      if(@forum.save)
        item=ForumItem.create_new(@forum, params)
        if(item.save)
          link_=Link.create_new(type, object, "forum", @forum, relation)
          link=link_[:link]
          if(link!=nil)
            if(link.save)
              #flash[:notice] += "<br> forum #{@forum.subject} was successfully added:rel=#{relation}:#{link_[:msg]}"
              flash[:notice] += t(:ctrl_object_added,:typeobj =>t(:ctrl_forum),:ident=>@forum.subject,:relation=>relation,:msg=>t(link_[:msg]))
            else
              #flash[:notice] += "<br> forum #{@forum.subject} was not added:rel=#{relation}:#{link_[:msg]}"
              flash[:notice] += t(:ctrl_object_not_added,:typeobj =>t(:ctrl_forum),:ident=>@forum.subject,:relation=>relation,:msg=>t(link_[:msg]))
              @forum.destroy
              error=true
            end
          else
            #flash[:notice] += "<br> link #{@forum.subject} was not created:rel=#{relation}:#{link_[:msg]}"
            flash[:notice] += t(:ctrl_object_not_linked,:typeobj =>t(:ctrl_forum),:ident=>@forum.subject,:relation=>relation,:msg=>nil)
            @forum.destroy
            error=true
          end
        else
          flash[:notice] += t(:ctrl_object_not_created, :typeobj =>t(:ctrl_forum_item))
          @forum.destroy
          error=true
        end
      else
        #flash[:notice] += "<br> forum #{@forum.subject} was not saved:rel=#{relation}:#{link_[:msg]}"
        flash[:notice] += t(:ctrl_object_not_saved,:typeobj =>t(:ctrl_forum),:ident=>@forum.subject,:relation=>relation,:msg=>link_[:msg])
        error=true
      end
      if error==false
        format.html { redirect_to(object) }
      else
        puts 'PlmObjectControllerModule.add_forum:id='+object.id.to_s
        @types=Typesobject.find_for("forum")
        @status= Statusobject.find_for("forum")
        format.html { render  :action => :new_forum, :id => object.id   }
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
    puts "PlmObjectControllerModule.add_favori:#{params.inspect}"
    model=get_model(params)
    obj=model.find(params[:id])
    puts "PlmObjectControllerModule.add_favori:#{obj.inspect}"
    @favori.add(obj)
    puts "PlmObjectControllerModule.add_favori:#{@favori.get_controller_from_model_type("user").inspect}"
    puts "PlmObjectControllerModule.add_favori:#{@favori.get("user").inspect}"
  end

  def empty_favori_by_type(type=nil)
    @favori.reset(type)
  end

  def empty_favori
    puts "===PlmObjectControllerModule.empty_favori"+params.inspect
    empty_favori_by_type(get_model_type(params))
  end

  def get_model_type(params)
    # enlever le 's' de fin
    # :controller=>parts devient part
    params[:controller].chop
  end

  def get_controller_from_model_type(model_type)
    # ajouter le 's' de fin
    # parts devient parts
    model_type+"s"
  end

  def get_model(params)
    # parts devient Part
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
        :label  => (link.name||t(:ctrl_no_relation))+'-'+t("ctrl_"+model_name)+':'+f.ident,
        :icon=>icone(f),
        :title => f.designation,
        :url=>url_for(url),
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
    unless obj.type.nil? || obj.typesobject.nil?
      ret="../images/"+obj.type.to_s+"_"+obj.typesobject.name+".png"
      unless File.exist?(ret)
        ret="../images/"+obj.type.to_s+".png"
        unless File.exist?(ret)
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

end
