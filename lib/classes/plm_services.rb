class PlmServices
  def self.get_object(type, id)
    # parts devient Part
    aname = "PlmServices."+__method__.to_s+":"
    typec = type.camelize
    #LOG.info {aname+type+";"+typec+"."+id.to_s}
    ret = nil
    begin
      mdl = eval typec
    rescue Exception => e
      LOG.warn{aname+e.message}
      begin
        typec ="Ruote::Sylrplm::"+typec
        mdl = eval typec
      rescue Exception => e
        LOG.error{aname+e.message}
      end
    end
    unless mdl.nil?
      begin
        ret = mdl.find(id)
      rescue Exception => e
        LOG.error{aname+e.message}
      end
    end
    LOG.info {aname+type+" ret="+(ret.nil? ? "" : ret.ident)}
    ret
  end
end