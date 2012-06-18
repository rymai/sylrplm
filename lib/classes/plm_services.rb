class PlmServices
	def self.get_object(type, id)
		# parts devient Part
		fname = "PlmServices.#{__method__}(#{type},#{id})"
		typec = type.camelize
		ret = nil
		begin
			mdl = eval typec
		rescue Exception => e
		#LOG.warn{aname+e.message}
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
		LOG.debug (fname){"ret=#{(ret.nil? ? "" : ret.ident)}"}
		ret
	end
end