class InfoController < ApplicationController
  access_control (Access.findForController(controller_class_name()))
  
  
  def which_documents
    part =Part.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    logger.error("Part non trouvee: #{params[:id]}")
    #flash[:notice] = "Part invalide"
    #@part=nil
    #@documents=nil
    render(:text, :text=>t(:info_object_not_found, context=>"which_documents",:object=>:ctrl_part,:id=>params[:id]))
  else
    @part=part
    @documents=@part.documents
  end
end
