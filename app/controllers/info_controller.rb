class InfoController < ApplicationController
  access_control(Access.find_for_controller(controller_class_name))

  def which_documents
    part = Part.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    LOG.error("Part non trouvee: #{params[:id]}")
    render(:text, :text => t(:info_object_not_found, context => "which_documents", :object => :ctrl_part, :id => params[:id]))
  else
    @part      = part
    @documents = @part.documents
  end

end