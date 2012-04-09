module Controllers
  module PlmObjectControllerModule
    def self.included(base)
      base.extend(ClassMethods)
    end

    # methodes de classe
    module ClassMethods

    # ClassMethods
    end

    require 'controllers/plm_tree'

    def add_favori
      fname="#{controller_class_name}.#{__method__}"
      LOG.info(fname) {"params=#{params.inspect}"}
      model = get_model(params)
      obj = model.find(params[:id])
      @favori.add(obj)
    end

    require 'controllers/plm_favorites'
    require 'controllers/plm_lifecycle'

    def ctrl_add_forum(object)
      fname= "#{self.class.name}.#{__method__}"
      LOG.info (fname){"params=#{params.inspect}"}
      type=object.model_name
      if params["relation_id"] == ""
        forum_type=Typesobject.find(params[:forum][:typesobject_id])
        relation = Relation.by_types(type, "forum", object.typesobject.id, forum_type.id)
      else
        relation = Relation.find(params["relation_id"])
      end
      error=false
      respond_to do |format|
        flash[:notice] = ""
        @forum=Forum.create_new(params[:forum], current_user)
        @forum.owner=@current_user
        if @forum.save
          item=ForumItem.create_new(@forum, params, current_user)
          if item.save
            unless relation.nil?
              link_=Link.create_new(object, @forum, relation, current_user)
              link=link_[:link]
              unless link.nil?
                if link.save
                  flash[:notice] << t(:ctrl_object_added,:typeobj =>t(:ctrl_forum),:ident=>@forum.subject,:relation=>relation.ident,:msg=>t(link_[:msg]))
                else
                  flash[:notice] << t(:ctrl_object_not_added,:typeobj =>t(:ctrl_forum),:ident=>@forum.subject,:relation=>relation.ident,:msg=>t(link_[:msg]))
                @forum.destroy
                error=true
                end
              else
                msg=$!
                flash[:notice] << t(:ctrl_object_not_linked,:typeobj =>t(:ctrl_forum),:ident=>@forum.subject,:relation=>relation.ident,:msg=>msg)
              @forum.destroy
              error=true
              end
            else
              flash[:notice] << t(:ctrl_object_not_created,:typeobj =>t(:ctrl_forum),:ident=>@forum.subject,:relation=>"no relation",:msg=>nil)
            @forum.destroy
            error=true
            end
          else
            msg=$!
            flash[:notice] << t(:ctrl_object_not_created, :typeobj =>t(:ctrl_forum_item),:msg=>msg)
          @forum.destroy
          error=true
          end
        else
          flash[:notice] << t(:ctrl_object_not_saved,:typeobj =>t(:ctrl_forum),:ident=>@forum.subject,:relation=>relation.ident,:msg=>nil)
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

    def html_models_and_columns(default = nil)
      lst=[]
      Dir.new("#{RAILS_ROOT}/app/models").entries.each do |model|
        unless %w[. .. _obsolete _old Copy].include?(model)
          mdl = model.camelize.gsub('.rb', '')
          begin
            mdl.constantize.content_columns.each do |col|
              lst<<["#{mdl}.#{col.name}","#{mdl}.#{col.name}"] unless %w[created_at updated_at owner].include?(col.name)
            end
          rescue
          # do nothing
          end
        end
      end
      #puts __FILE__+"."+__method__.to_s+":"+lst.inspect
      get_html_options(lst, default)
    end

    def  get_html_options(lst, default, translate=false)
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

  end
end
