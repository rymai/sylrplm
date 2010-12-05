module Controllers::PlmObjectControllerModule
  
  def ctrl_revise(model)
    define_variables
    object = model.find(params[:id])
    previous_rev=object.revision
    @object=object.revise
    @types=Typesobject.getTypes(object.class.name.downcase!)
    respond_to do |format|
      if(@object != nil)
        if @object.save
          puts object.class.name+'.revision apres save='+@object.id.to_s+":"+@object.revision;
          flash[:notice] = t(:ctrl_object_revised,:object=>t(:ctrl_.to_s+@object.class.name.downcase!),:ident=>@object.ident,:previous_rev=>previous_rev,:revision=>@object.revision)
          format.html { redirect_to(@object) }
          format.xml  { head :ok }
        else
          format.html { render :action => "edit" }
          format.xml  { render :xml => object.errors, :status => :unprocessable_entity }
        end
      else
        @object = model.find(params[:id])
        flash[:notice] = t(:ctrl_object_not_revised,:object=>t(:ctrl_.to_s+@object.class.name.downcase!),:ident=>@object.ident,:previous_rev=>previous_rev)
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
      askUserMail=object.owner.email
      puts "plm_object_controller.ctrl_promote:"+askUserMail.to_s+"|"
      if askUserMail==nil
        puts "plm_object_controller.ctrl_promote:pas de mail"
        email_ok=false
      end
    end
    respond_to do |format|
      if email_ok==true
        current_rank=object.statusobject.name
        object.promote
        new_rank=object.statusobject.name
        current_rank!=new_rank
        if object.save
          if withMail==true
            email=nil 
            validers=User.find_validers             
            if object.is_to_validate
              validersMail=PlmMailer.listUserMail(validers)
              email=PlmMailer.create_toValidate(object, @usermail, @urlbase, validersMail) 
            end
            if object.is_freeze
              validersMail=PlmMailer.listUserMail(validers,@user)
              email=PlmMailer.create_validated(object, @usermail, @urlbase, askUserMail, validersMail)
            end
            if email!=nil && email!=""
              email.set_content_type("text/html")
              PlmMailer.deliver(email)
            end
          end
          flash[:notice] = t(:ctrl_object_promoted,:object=>t(:ctrl_.to_s+object.class.name.downcase!),:ident=>object.ident,:current_rank=>current_rank,:new_rank=>new_rank,:validersMail=>validersMail)
          format.html { redirect_to(object) }
          format.xml  { head :ok }
        else
          flash[:notice] = t(:ctrl_object_not_promoted,:object=>t(:ctrl_.to_s+object.class.name.downcase!),:ident=>object.ident,:current_rank=>current_rank,:new_rank=>new_rank,:validersMail=>validersMail)
          format.html { render :action => "edit" }
          format.xml  { render :xml => object.errors, :status => :unprocessable_entity }
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
              email=PlmMailer.create_docToValidate(object, @usermail, @urlbase, validersMail) 
            end
            if object.is_freeze
              validersMail=PlmMailer.listUserMail(validers,@user)
              email=PlmMailer.create_docValidated(object, @usermail, @urlbase, askUserMail, validersMail)
            end
            if(email!=nil)
              email.set_content_type("text/html")
              PlmMailer.deliver(email)
            end
          end
          flash[:notice] = t(:ctrl_object_demoted,:object=>t(:ctrl_.to_s+object.class.name.downcase!),:ident=>object.ident,:current_rank=>current_rank,:new_rank=>new_rank,:validersMail=>validersMail)
          format.html { redirect_to(object) }
          format.xml  { head :ok }
        else
          flash[:notice] = t(:ctrl_object_not_demoted,:object=>t(:ctrl_.to_s+object.class.name.downcase!),:ident=>object.ident,:current_rank=>current_rank,:new_rank=>new_rank)
          format.html { render :action => "edit" }
          format.xml  { render :xml => object.errors, :status => :unprocessable_entity }
        end
      else
        flash[:notice] = t(:ctrl_object_not_demoted,:object=>t(:ctrl_.to_s+object.class.name.downcase!),:ident=>object.ident,:current_rank=>current_rank,:new_rank=>new_rank,:validersMail=>validersMail)
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
              :label  => t(:ctrl_part)+":"+obj.ident+cut_a,
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
                        :label  => t(:ctrl_project)+":"+obj.ident+cut_a,
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
  
  def tree_customer(obj)  
    if(obj!=nil) 
      url={:controller => 'customers', :action => 'show', :id => "#{obj.id}"}
      options={
                      :label  => t(:ctrl_customer)+":"+obj.ident,
                      :icon=>icone(obj),
        # :icon_open=>"",
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
  
  def icone(obj)
    if obj.type!=nil && obj.typesobject!=nil
      "../images/"+obj.type.to_s+"_"+obj.typesobject.name+".png"
    else
      ""
    end
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
  
  def follow_tree_part(node, part,ctrl)
    #part.projects.each do |d|
    #  cnode = tree_project(d)        
    #  node << cnode
    #non car bouclage follow_tree_project(node,d)
    #end
    tree_forums(node,"part",part,ctrl)  
    tree_documents(node,"part",part,ctrl) 
    links=Link.find_childs("part", part,  "part")
    links.each do |link|
      child=Part.find(link.child_id) 
      url={:controller => 'parts', :action => 'show', :id => "#{child.id}"}
      #link_to_remote= {
      #       :url => url,
      #       :update => "content",
      #       :base => self
      #     }
      #link_to=url
      destroy_url=url_for(:controller => ctrl.controller_name,
                                   :action => "remove_link",
                                   :id => link.id)
      cut_a='<a href="'+destroy_url+'">'+img_cut+'</a>' 
      options={
                :label  => (link.name||'no_relation')+'-'+t(:ctrl_part)+':'+child.ident+cut_a,
                :icon=>icone(child),
        #:icon_open=>icone(child),
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
    links=Link.find_fathers("part", part,  "part")
    links.each do |link|
      f=Part.find(link.father_id) 
      url={:controller => 'parts', :action => 'show', :id => "#{f.id}"}
      options={
                :label  => (link.name||'no_relation')+'-'+t(:ctrl_part)+':'+f.ident,
                :icon=>icone(f),
        # :icon_open=>"",
                :title => f.designation,
                :url=>url_for(url),
              :open => false
      }
      html_options = {   
              :alt => "alt:"+f.ident
      }
      cnode = Node.new(options)          
      node << cnode
      # projets
      links=Link.find_fathers("part", part,  "project")
      links.each do |link|
        f=Project.find(link.father_id) 
        url={:controller => 'projects', :action => 'show', :id => "#{f.id}"}
        link_to_remote= {
                     :url => url,
                     :update => "content",
                     :base => self
        }
        link_to=url
        options={
                  :label  => t(:link_project,:link=>link.name,:ident=>f.ident),
          # :icon=>"",
          # :icon_open=>"",
                  :title => f.designation,
                  :url=>url_for(url),
                :open => false
        }
        cnode = Node.new(options)          
        node << cnode
        
      end
    end
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
  
  def follow_tree_project(node, obj,ctrl)
    tree_documents(node,"project",obj,ctrl) 
    tree_forums(node,"project",obj,ctrl)  
    #if(obj.customer!=nil)
    #    cnode=tree_customer(obj.customer)
    #    node<<cnode    
    #  end
    links=Link.find_childs("project", obj,  "part")
    links.each do |link|
      child=Part.find(link.child_id)
        pnode=tree_part(child, link,ctrl)
        node<<pnode       
        follow_tree_part(pnode, child,ctrl)
      end
  end
  
  def follow_tree_up_project(node, project,ctrl)
          links=Link.find_fathers("project", project,  "customer")
          links.each do |link|
            c=Customer.find(link.father_id) 
            url={:controller => 'customers', :action => 'show', :id => "#{c.id}"}
            options={
                :label  => (link.name||'no_relation')+'-'+t(:ctrl_customer)+':'+c.ident,
                :icon=>icone(c),
                # :icon_open=>"",
                :title => c.designation,
                :url=>url_for(url),
              :open => false
            }
            cnode = Node.new(options)          
            node << cnode
          end
  end
  
  def tree_documents(node, father_object, father,ctrl)
      docs=Link.find_childs(father_object, father,  "document")
      docs.each do |link|
          d=Document.find(link.child_id)
          url={:controller => 'documents', :action => 'show', :id => "#{d.id}"}        
          destroy_url=url_for(:controller => ctrl.controller_name,
                              :action => "remove_link",
                              :id => "#{link.id}" )
          cut_a='<a href="'+destroy_url+'">'+img_cut+'</a>'   
          options={
                   :label => (link.name||'no_relation')+'-'+t(:ctrl_document)+':'+d.ident + cut_a,
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
  def tree_forums(node, father_object, father,ctrl)
      docs=Link.find_childs(father_object.to_s, father,  "forum")
      docs.each do |link|
          d=Forum.find(link.child_id)
          url={:controller => 'forums', :action => 'show', :id => "#{d.id}"}        
          destroy_url=url_for(:controller => ctrl.controller_name,
                              :action => "remove_link",
                              :id => "#{link.id}" )
          if d.is_freeze() == false 
              cut_a='<a href="'+destroy_url+'">'+img_cut+'</a>'   
          else 
              cut_a=""
          end
          options={
                   :label => (link.name||'no_relation')+'-'+t(:ctrl_forum)+':'+d.subject + cut_a,
                   :icon=>icone(d),
                   #:icon_open=>icone(d),
                   :title => d.subject,
                   :open => false,
                   :url=>url_for(url)
          }
          cnode = Node.new(options,nil)          
          node<<cnode   
      end
  end
  def remove_link
    link = Link.remove(params[:id])
    respond_to do |format|      
     #flash[:notice] = t(:ctrl_nothing_to_paste,:object=>t(:ctrl_document))
      format.html { redirect_to(session[:tree_object]) }
      format.xml  { head :ok }
      end
    #uri=session[:original_uri]
    #session[:original_uri]=nil
    #redirect_to(uri || {:controller => "main", :action => "index"})
  end
  
  def ctrl_add_forum(object,type)
    relation="forum"
    error=false
    respond_to do |format|      
      flash[:notice] = ""
      @forum=Forum.new(params[:forum])
      @forum.creator=@user
      if(@forum.save)
        item=ForumItem.create_new(@forum, params)
        if(item.save)
          link_=Link.create_new(type, object, "forum", @forum, relation)  
          link=link_[:link]
          if(link!=nil) 
            if(link.save)
              #flash[:notice] += "<br> forum #{@forum.subject} was successfully added:rel=#{relation}:#{link_[:msg]}"
              flash[:notice] += t(:ctrl_object_added,:object=>t(:ctrl_forum),:ident=>@forum.subject,:relation=>relation,:msg=>t(link_[:msg]))
            else
              #flash[:notice] += "<br> forum #{@forum.subject} was not added:rel=#{relation}:#{link_[:msg]}"
              flash[:notice] += t(:ctrl_object_not_added,:object=>t(:ctrl_forum),:ident=>@forum.subject,:relation=>relation,:msg=>t(link_[:msg]))
              @forum.destroy
              error=true
            end 
          else
            #flash[:notice] += "<br> link #{@forum.subject} was not created:rel=#{relation}:#{link_[:msg]}"
            flash[:notice] += t(:ctrl_object_not_linked,:object=>t(:ctrl_forum),:ident=>@forum.subject,:relation=>relation,:msg=>nil)
            @forum.destroy 
            error=true
          end
        else
          flash[:notice] += t(:ctrl_object_not_created, :object=>t(:ctrl_forum_item))
          @forum.destroy 
          error=true
        end
      else
        #flash[:notice] += "<br> forum #{@forum.subject} was not saved:rel=#{relation}:#{link_[:msg]}"
        flash[:notice] += t(:ctrl_object_not_saved,:object=>t(:ctrl_forum),:ident=>@forum.subject,:relation=>relation,:msg=>link_[:msg])
        error=true
      end
      if error==false
        format.html { redirect_to(object) }
      else
        puts 'PartController.add_forum:id='+object.id.to_s
        @types=Typesobject.find_for("forum")
        @status= Statusobject.find_for("forum")
        format.html { render  :action => :new_forum, :id => object.id   }
      end
      format.xml  { head :ok }
    end
  end 
  
  def ctrl_add_datafile(object,type)
    relation="datafile"
    error=false
    respond_to do |format|      
      flash[:notice] = ""
      puts "plm_object_controller.ctrl_add_datafile:user="+@user.inspect
      @datafile=Datafile.create_new(params,@user)
      if(@datafile.save)
          link_=Link.create_new(type, object, "datafile", @datafile, relation)  
          link=link_[:link]
          if(link!=nil) 
            if(link.save)
              flash[:notice] += t(:ctrl_object_added,:object=>t(:ctrl_datafile),:ident=>@datafile.ident,:relation=>relation,:msg=>t(link_[:msg]))
            else
              flash[:notice] += t(:ctrl_object_not_added,:object=>t(:ctrl_datafile),:ident=>@datafile.ident,:relation=>relation,:msg=>t(link_[:msg]))
              @datafile.destroy
              error=true
            end 
          else
            flash[:notice] += t(:ctrl_object_not_linked,:object=>t(:ctrl_datafile),:ident=>@datafile.ident,:relation=>relation,:msg=>nil)
            @datafile.destroy 
            error=true
          end
      else
        flash[:notice] += t(:ctrl_object_not_saved,:object=>t(:ctrl_datafile),:ident=>@datafile.ident,:relation=>relation,:msg=>nil)
        error=true
      end
      if error==false
        format.html { redirect_to(object) }
      else
        puts 'plm_object_controller.add_datafile:id='+object.id.to_s
        @types=Typesobject.find_for("datafile")
        format.html { render  :action => :new_datafile, :id => object.id   }
      end
      format.xml  { head :ok }
    end
  end 
  
  def get_nb_items(nb_items)
    unless nb_items.nil? || nb_items==""
      nb_items
    else
      unless session[:nb_items].nil?
        session[:nb_items]
      else
        SYLRPLM::NB_ITEMS_PER_PAGE
      end
    end
  end
  
  
end
