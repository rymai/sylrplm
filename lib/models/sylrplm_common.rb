
module SylrplmCommon
  
 
  def self.find_paginate(params)
    self.paginate(:page => params[:page], 
    :conditions => params[:cond],
    :order => params[:sort],
      :per_page => params[:nbr])
  end 
  
end