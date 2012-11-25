def empty_favori_by_type(type=nil)
  puts "===PlmObjectControllerModule.empty_favori_by_type"+type.to_s
  @favori.reset(type)
end

def empty_favori
  puts "===PlmObjectControllerModule.empty_favori"+params.inspect
  empty_favori_by_type(get_model_type(params))
end

def ctrl_add_objects_from_favorites(object, child_plmtype)
  LOG.info("#{controller_class_name}.#{__method__}") {"#{object.inspect}.#{child_plmtype}"}
  relation = Relation.find(params[:relation][child_plmtype])
  plmtype = child_plmtype.to_s
  ctrltype = t("ctrl_#{plmtype}")
  respond_to do |format|
    unless @favori.get(plmtype).nil?
      flash[:notice] = ""
      @favori.get(plmtype).each do |item|
        link = Link.new(father: object, child: item, relation: relation, user: current_user)
        if link.save
          flash[:notice] << t(:ctrl_object_added,
                              :typeobj => ctrltype,
                              :ident => item.ident,
                              :relation => relation.ident,
                              :msg => "ctrl_link_#{link.ident}")
          empty_favori_by_type(plmtype)
        else
          flash[:notice] << t(:ctrl_object_not_added,
                              :typeobj => ctrltype,
                              :ident => item.ident,
                              :relation => relation.ident,
                              :msg => link.errors.first)
        end
        # else
        #   flash[:notice] << t(:ctrl_object_not_linked,
        #         :typeobj => ctrltype,
        #         :ident => item.ident,
        #         :relation => relation.ident,
        #         :msg => link_[:msg])
        # end
      end
    else
      flash[:notice] = t(:ctrl_nothing_to_paste, :typeobj => ctrltype)
    end
    format.html { redirect_to(object) }
    format.xml  { head :ok }
  end
end

