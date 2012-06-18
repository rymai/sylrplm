require 'openwfe/extras/participants/ar_participants'

module Ruote
	module Sylrplm
		class ArWorkitem < OpenWFE::Extras::ArWorkitem
			#include Models::PlmObject
			attr_accessor :link_attributes
			def link_attributes=(att)
				@link_attributes = att
			end

			def link_attributes
				@link_attributes
			end

			def typesobject
				Typesobject.find_by_object(model_name)
			end

			def model_name
				"ar_workitem"
			end

			def ident
				fei+"_"+wfid+"_"+expid+"_"+wfname
				[wfid,expid,wfname].join("_")
			end

			def cancel?
				histo=Ruote::Sylrplm::HistoryEntry.find_by_wfid_and_source_and_event(self.wfid,"expool","cancel")
				!histo.nil?
			end

			# delete of workitems of a process
			def self.destroy_process(wfid)
				LOG.info {wfid}
				ArWorkitem.find_by_wfid_(wfid).each do |ar|
					ar.destroy
				end
			end

			def before_destroy
				fname="ArWorkitem."+__method__.to_s+":"
				links=Link.find_childs(self)
				LOG.info {fname+(links.nil? ? "0" : links.count.to_s)+" liens a detruire"}
				links.each {|lnk| lnk.destroy}
			end

			def get_wi_links
				fname="ArWorkitem."+__method__.to_s+":"
				ret=[]
				Link.find_childs(self,"document").each do |link|
					ret<<{:typeobj =>Document.find(link.child_id), :link=>link}
				end
				Link.find_childs(self,"part").each do |link|
					ret<<{:typeobj =>Part.find(link.child_id), :link=>link}
				end
				Link.find_childs(self,"project").each do |link|
					ret<<{:typeobj =>Product.find(link.child_id), :link=>link}
				end
				Link.find_childs(self,"customer").each do |link|
					ret<<{:typeobj =>Customer.find(link.child_id), :link=>link}
				end
				Link.find_childs(self,"user").each do |link|
					ret<<{:typeobj =>User.find(link.child_id), :link=>link}
				end
				LOG.debug {fname+id.to_s+":"+ret.size.to_s+":"+ret.inspect}
				ret
			end

			#return associated objects during process
			def objects
				params=self.field_hash[:params]
				ret=[]
				unless params.nil?
					activity=params[:activity]
					params.delete(:activity)
					ret = {:act => activity, :obj => params.values}
				end
				ret
			end

		end
	end
end
