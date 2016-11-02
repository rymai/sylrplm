def empty_clipboard_by_type(type=nil)
  fname="#{self.class.name}.#{__method__}"
  LOG.info(fname) {"type=#{type}"}
  @clipboard.reset(type)
end



def empty_clipboard_obsolete
  fname="#{self.class.name}.#{__method__}"
  LOG.info(fname) {"params=#{params.inspect}"}
  empty_clipboard_by_type(get_model_type(params))
end

def ctrl_add_objects_from_clipboardtes(object, child_plmtype, flash)
	fname="#{self.class.name}.#{__method__}"
	LOG.info(fname) {"object=#{object} child_plmtype=#{child_plmtype}"}
	if child_plmtype.nil?
		#["document", "part", "project", "customer", "user"].each do |childplmtype|
		LOG.info(fname) {"params[:objecttoadd]=#{params[:objecttoadd]}"}
		unless params[:objecttoadd].nil?
			params[:objecttoadd].each do |childplmtype, value|
				flash = add_objects_from_clipboardtes(object, childplmtype, flash)
			end
		end
	else
		flash = add_objects_from_clipboardtes(object, child_plmtype, flash)
	end
	respond_to do |format|
		format.html { redirect_to(object) }
   	format.xml  { head :ok }
  end
end

def add_objects_from_clipboardtes(object, child_plmtype, flash)
	fname="#{self.class.name}.#{__method__}"
  	LOG.info(fname) {"object=#{object} child_plmtype=#{child_plmtype}"}
  	#LOG.info(fname) {"#{object.inspect}.#{child_plmtype}"}
    LOG.info(fname) {"params[:relation]=#{params[:relation]}"}
    LOG.info(fname) {"params[:commit]=#{params[:commit]}"}
    LOG.info(fname) {"params[:objecttoadd]=#{params[:objecttoadd]}"}
    LOG.info(fname) {"params[:controller]=#{params[:controller]}"}
    LOG.info(fname) {"params[:action]=#{params[:action]}"}
    LOG.info(fname) {"params[:id]=#{params[:id]}"}
  	begin

	  	#LOG.info(fname) {"notice=#{flash[:notice]}"}
	  	clipboards_to_add=params[:objecttoadd][child_plmtype]
	  	#LOG.info(fname) {"clipboards to add=#{clipboards_to_add}"}
	  	unless object.nil?
	  	  #objecttoadd[#{clipboard.modelname}][#{clipboard.id}][#{relation.id}]
		 	unless params[:objecttoadd][child_plmtype].nil?
		     params[:objecttoadd][child_plmtype].each do |clipboard_id, clipboard_val|
	          LOG.info(fname) {"clipboard_id=#{clipboard_id} clipboard_val=#{clipboard_val} "}
	        clipboard_val.each do |relation_id, val|
	          LOG.info(fname) {"relation_id=#{relation_id} val=#{val}"}
	    			relation = Relation.find(relation_id)
			  		plmtype = child_plmtype.to_s
			  		ctrltype = t("ctrl_#{plmtype}")
			  		unless @clipboard.get(plmtype).nil?
				  		@clipboard.get(plmtype).each do |item|
				      		clipboard_item=clipboards_to_add[item.id.to_s]
				      		LOG.info(fname) {"adding? item=#{item.id} : #{clipboard_item}"}
				      		# object!=item : avoid to link object to himself
				      		if(object!=item && !clipboard_item.nil?)
				      			#LOG.info(fname) {"adding=#{item}"}
				        		link = Link.new(father: object, child: item, relation: relation, user: current_user)
				        		if link.save
				        			flash[:notice] << t(:ctrl_object_added,
				            	 		:typeobj => ctrltype,
				               			:ident => item.ident,
				               			:relation => relation.ident,
				               			:msg => "ctrl_link_#{link.ident}")
				             		@clipboard.remove(item)
				        		else
				          			flash[:notice] << t(:ctrl_object_not_added,
				               			:typeobj => ctrltype,
				               			:ident => item.ident,
				               			:relation => relation.ident,
				               			:msg => link.errors.first)
				        		end
				      		end
				    	end
				    	end
				 	end
				end
			else
				flash[:notice] << t(:ctrl_nothing_to_paste, :typeobj => ctrltype)
			end
		else
	  		flash[:error] << t(:ctrl_object_not_found, :typeobj => "" , :ident => "")
	  	end
  	rescue Exception=>e
  		#TODO translate
  		flash[:notice] << "Error durant le sauve du lien : #{e}"
  	end
 	flash
end
