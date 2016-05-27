class InfoController < ApplicationController
  access_control(Access.find_for_controller(controller_name.classify))
  def list_objects
    fname= "#{self.class.name}.#{__method__}"
    LOG.debug(fname) {"params=#{params.inspect}"}
    param={}
    param[:controller]=params[:plmtype]
    mdl = get_model param
    @plm_objects  = mdl.find(:all)
  rescue ActiveRecord::RecordNotFound
    LOG.error("Objects non trouves:")
    render(:text, :text => t(:info_objects_not_found, :context => "list_objects", :plmtype => :plmtype))
    end

  def object_links
    fname= "#{self.class.name}.#{__method__}"
    LOG.debug(fname) {"params=#{params.inspect}"}
    param={}
    param[:controller]=params[:plmtype]
    mdl = get_model param
    @plm_object  = mdl.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    LOG.error("Object non trouvee: #{:plmtype}.#{params[:id]}")
    render(:text, :text => t(:info_object_not_found, :context => "object_documents", :typeobj => "ctrl_#{:plmtype}", :id => params[:id]))
    end

end