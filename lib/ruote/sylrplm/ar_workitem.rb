require 'openwfe/extras/participants/ar_participants'

module Ruote
	module Sylrplm
		class ArWorkitem < OpenWFE::Extras::ArWorkitem
			#include Models::PlmObject
			attr_accessor :link_attributes
			def get_hash_objects; objects; end

			def link_attributes=(att)
				@link_attributes = att
			end

			def link_attributes
				@link_attributes
			end

			def typesobject
				::Typesobject.find_by_object(model_name)
			end

			def model_name
				"ar_workitem"
			end

			def ident
				#fei+"_"+wfid+"_"+expid+"_"+wfname
				[wfid,expid,wfname].join("_")
			end

			def cancel?
				histo=Ruote::Sylrplm::HistoryEntry.find_by_wfid_and_source_and_event(self.wfid, "expool", "cancel")
				!histo.nil?
			end

			# delete of workitems of a process
			def self.destroy_process(wfid)
				fname="ArWorkitem.#{__method__}"
				LOG.info (fname) {"wfid=#{wfid}"}
				find_by_wfid_(wfid).each do |ar|
					LOG.info (fname) {"workitem to destroy=#{ar}"}
					ar.destroy
				end
			end

			def before_destroy
				fname="ArWorkitem."+__method__.to_s+":"
				links=Link.find_childs(self)
				LOG.info (fname) {"#{(links.nil? ? "0" : links.count.to_s)} liens a detruire"}
				links.each {|lnk| lnk.destroy}
			end

			def get_wi_links
				fname="ArWorkitem.#{__method__}"
				ret=[]
				history=HistoryEntry.find_by_wfid_and_event(self.wfid, "proceeded")
				unless history.nil?
					Link.find_childs(history, "document").each do |link|
						ret<<{:typeobj =>Document.find(link.child_id), :link=>link}
					end
					Link.find_childs(history, "part").each do |link|
						ret<<{:typeobj =>Part.find(link.child_id), :link=>link}
					end
					Link.find_childs(history, "project").each do |link|
						ret<<{:typeobj =>Product.find(link.child_id), :link=>link}
					end
					Link.find_childs(history, "customer").each do |link|
						ret<<{:typeobj =>Customer.find(link.child_id), :link=>link}
					end
					Link.find_childs(history, "user").each do |link|
						ret<<{:typeobj =>User.find(link.child_id), :link=>link}
					end
				end
				LOG.debug (fname) {"id=#{self.id}, size=#{ret.size}:#{ret.inspect}"}
				ret
			end

			def get_plm_objects
				fname="ArWorkitem.#{__method__}"
				hash_objects=get_hash_objects
				ret=[]
				LOG.debug (fname) {"hash_objects=#{hash_objects} obj=#{hash_objects[:obj]} "}
				hash_objects[:obj].each do |key|
					tab=key.split("/")
					LOG.debug (fname) {"mdl=#{tab[1]}  id=#{tab[2]} "}
					#TODO remplacer chop par une fonction de service
					plmobj=PlmServices.get_object(tab[1].chop, tab[2])
					ret<< plmobj
				end
				LOG.debug (fname) {"ret=#{ret.inspect}"}
				ret
			end

			#return associated objects during process
			def objects
				fname="ArWorkitem.#{__method__}"
				params=self.field_hash["params"]
				ret=[]
				unless params.nil?
					activity=params["activity"]
					params.delete("activity")
					ret = {:act => activity, :obj => params.keys}
				end
				LOG.debug (fname) {"self.field_hash=#{self.field_hash} params=#{params.inspect} ret=#{ret}"}
				ret
			end

			def self.get_workitem(wfid)
				fname="ArWorkitem.#{__method__}"
				#LOG.debug (fname) {"wfid=#{wfid}"}
				require 'pg'
				#show_activity
				ret = find(:first, :conditions => ["wfid = '#{wfid}'"])
				#ret = find_by_wfid(wfid)
				#LOG.debug (fname) {"ret=#{ret}"}
				ret
			end

			# add an object in fields
			def add_object(object)
				fname="ArWorkitem.#{__method__}"
				ret=0
				type_object=object.model_name
				fields = self.field_hash
				if fields == nil
					fields = {}
					fields["params"] = {}
				end
				url="/"+type_object+"s"
				url+="/"+object.id.to_s
				label=type_object+":"+object.ident
				unless fields["params"][url]==label
					fields["params"][url]=label
				ret+=1
				self.replace_fields(fields)
				else
					LOG.info (fname) {"objet deja present dans cette tache"}
				end
				ret
			end

			def show_activity
				# Output a table of current connections to the DB
				conn = PG.connect( :dbname => "sylrplm_development" , :user => "postgres", :password => "pa33zp62" )
				conn.exec( "SELECT * FROM pg_stat_activity" ) do |result|
					puts "     PID | User             | Query"
					result.each do |row|
						puts " %7d | %-16s | %s " %
				        row.values_at('pid', 'usename', 'query')
					end
				end
			end

		end
	end
end
