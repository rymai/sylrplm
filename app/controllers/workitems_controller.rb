require "ruote/workitem"

#
# ruote workitems
#
class WorkitemsController < ApplicationController
	include Ruote
	include Ruote::Sylrplm
	def index
		index_
	end

	def show
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug(fname){"params="+params.inspect}
		#@workitem =  RuoteKit.storage_participant[params[:id]]
		sleep 0.2
		@workitem = Ruote::Sylrplm::ArWorkitem.find_by_wfid(params[:wfid])
		LOG.debug(fname){"@workitem="+@workitem.inspect}
		return error_reply('no workitem', 404) unless @workitem
		@wi_links = @workitem.get_wi_links unless @workitem.nil?
		LOG.debug(fname){"@wi_links="+@wi_links.inspect}
	#@form = Form.for(@workitem)
	end

	# GET /workitems/:wfid/:expid/edit
	#
	def edit
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug(fname){"params="+params.inspect}
		@workitem = RuoteKit.storage_participant[params[:id]]
		return error_reply('no workitem', 404) unless @workitem
		LOG.debug(fname){"@workitem="+@workitem.inspect}
		LOG.debug(fname){"@workitem.fei="+@workitem.fei.to_h.inspect}
		LOG.debug(fname){"@workitem.participant="+@workitem.participant_name}
		LOG.debug(fname){"@workitem.params="+@workitem.params.inspect}
		LOG.debug(fname){"@workitem.fields="+@workitem.fields.inspect}
		@wi_links = @workitem.get_wi_links unless @workitem.nil?
		LOG.debug(fname){"@wi_links="+@wi_links.inspect}
		nb=0
		["document","part","project","customer","user"].each { |plm|
			nb+=add_objects_to_workitem(@workitem, plm)
		}
		LOG.debug(fname){"#{nb} fields=#{@workitem.fields}"}
		nb = 0
		ar_workitem = nil
		sleep 0.5
		while nb < 10 and ar_workitem.nil?
			nb+=1
			ar_workitem = find_ar_workitem(@workitem)
		end
		LOG.info(fname) {"apres sleep nb=#{nb}: ar_workitem=#{ar_workitem.inspect} "}
		if ar_workitem.nil?
			ar_workitem=Ruote::Sylrplm::ArWorkitem.create_from_wi(@workitem,current_user)
		else
			ar_workitem=Ruote::Sylrplm::ArWorkitem.update_from_wi(ar_workitem, @workitem,current_user)
		end
		LOG.debug(fname){"RuoteKit.engine.process:@workitem.wfid="+@workitem.wfid}
		process=RuoteKit.engine.process(@workitem.wfid)
		tree=nil
		tree = process.current_tree.to_json unless process.nil?
		LOG.debug(fname){"process=#{process} tree=#{tree}"}
		ar_workitem.tree=tree
		stsave=ar_workitem.save
		LOG.debug(fname){"ar_workitem stsave=#{stsave} sauve=#{ar_workitem}"}
		relation=@workitem.fields["relation"]
		unless relation.nil?
			create_links(ar_workitem, @workitem.wfid, relation)
		end
		RuoteKit.storage_participant.update(@workitem)
	end

	def update
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug(fname){"update:params=#{params}"}
		ok=true
		fields = Rufus::Json.decode(params[:workitem][:fields]) unless params[:workitem].blank?
		@workitem = RuoteKit.storage_participant[params[:id]]
		LOG.debug(fname) {"@workitems debut=#{RuoteKit.storage_participant.query(:wfid => @workitem.wfid).size}"}
		@workitem.fields.merge!(fields) unless fields.nil?
		submit = params[:state]
		LOG.debug(fname){"submit=#{submit}"}
		LOG.debug(fname){"workitem.wf_name=#{@workitem.wf_name}"}
		flash={:notice=>"", :error=>""}
		if submit == 'proceeded'
			LOG.debug(fname){"avant proceed workitem:#{@workitem} #{@workitem.sid}"}
			unless @workitem.nil?
				LOG.debug(fname){"avant proceed: fields workitem: #{@workitem.fields}"}
				# Returns nil in case of success, true if the workitem is already gone and the newer version of the workitem if the workitem changed in the mean time.
				st=RuoteKit.storage_participant.update(@workitem)
				LOG.debug(fname){"RuoteKit.storage_participant.update:#{st}"}
				LOG.debug(fname) {"@workitems proceed avant=#{RuoteKit.storage_participant.query(:wfid => @workitem.wfid).size}"}
				RuoteKit.storage_participant.proceed(@workitem)
				flash[:notice] = I18n.t('flash.notice.proceeded', :fei => @workitem.fei.sid)
				@workitems = RuoteKit.storage_participant
				LOG.debug(fname) {"@workitems proceed apres=#{RuoteKit.storage_participant.query(:wfid => @workitem.wfid).size}"}
			else
				LOG.debug(fname){"workitem is null"}
				flash[:error] = I18n.t('flash.error.not_proceeded', :fei => nil)
				ok=false
				LOG.error(fname){"1error=#{flash[:error]}"}
			end
		else
			if submit == 'release'
				@workitem.participant_name = 'anyone'
			elsif submit == 'take'
				@workitem.participant_name = session[:username]
			end
			RuoteKit.storage_participant.update(@workitem)
			LOG.debug(fname){"RuoteKit.storage_participant.update:#{st}"}
		end
		LOG.debug(fname) {"flash:#{flash}"}
		nb = 0
		arw = nil
		sleep 0.5
		while nb < 10 and arw.nil?
			sleep 0.2
			nb+=1
			#
			# recherche du workitem
			#
			arw = find_ar_workitem(@workitem)
		end
		LOG.info(fname) {"apres sleep nb=#{nb}: arw=#{arw.inspect} @workitem.wfid=#{@workitem.wfid}"}
		sleep 0.5
		begin
			@process=RuoteKit.engine.process(@workitem.wfid)
		rescue Exception=>e
			LOG.error(fname){"error recup process for #{@workitem.wfid} =#{e}"}
		end
		LOG.info(fname) {"apres RuoteKit.engine.process, process=#{@process}"}
		unless arw.nil?
			unless @process.nil?
				unless arw.error.blank?
					flash[:error] +="<br/>#{arw.error}"
					LOG.info(fname) {"apres RuoteKit.engine.process, errors=#{@process.errors.size}"}
					@process.errors << arw.error
					ok=false
					LOG.error(fname){"2error=#{@process.errors.full_messages}"}
				end
			else
				LOG.error(fname){"@process is nil"}
			ok=false
			end
			arw.def_user(current_user)
			arw.event=submit
			#??? arw.message = arw.objects
			arw.participant_name= @workitem.participant_name
			arw.save
			workitem_ident = "#{@workitem.fei.wfid}/#{PlmServices.to_uscores(@workitem.fei.expid)}"
			if arw.errors.count == 0
				flash[:notice] += t(:ctrl_workitem_proceeded, :ident => workitem_ident)
			else
			flash[:error] += t( :ctrl_workitem_not_proceeded, :ident => workitem_ident, :msg => arw.errors.inspect)
				unless @process.nil?
					arw.errors.each do |err|
						@process.errors.add(:base,err.message)
					end
				end
				ok=false
				LOG.error(fname){"4error=#{flash[:error]}"}
			end
		else
			ok=false
			flash[:error] += "<br/>ar_workitem not found"
			LOG.error(fname){"5error=#{flash[:error]}"}
		end
		unless ok
			#
			# error during  workitem processing, cancel the process
			#
			begin
				LOG.error(fname){"RuoteKit.engine.cancel_process(#{@process})"}
				RuoteKit.engine.cancel_process(@process.wfid) unless @process.nil?
			rescue Exception=>e
				LOG.error(fname){"RuoteKit.engine.cancel_process error=#{e}"}
			end
			flash[:error] += "<br/>#{t(:ctrl_process_canceled, :ident => params[:wfid])}"
		end
		respond_to do |format|
			LOG.error(fname) {"fin de update flash=#{flash}"}
			index_
			format.html do
				render :action => :index
			end
		end
	end

	:private

	def index_
		fname= "#{self.class.name}.#{__method__}"
		@workitems = RuoteKit.storage_participant.all(:order=>[:label,:wfid,:expid])
		LOG.debug(fname) {"@workitems=#{RuoteKit.storage_participant.query(:wfid => @workitem.wfid).size}"} unless @workitem.nil?
	end

	def add_objects_to_workitem(ar_workitem, type_object)
		fname= "#{self.class.name}.#{__method__}"
		msg=""
		ret=0
		clipboard=@clipboard.get(type_object)
		LOG.debug(fname){"type_object=#{type_object} clipboard=#{clipboard.inspect}"}
		if clipboard.count>0
			fields = ar_workitem.fields
			if fields == nil
				fields = {}
				fields["params"] = {}
			end
			clipboard.each do |item|
				LOG.debug(fname){"clipboard=#{item.inspect}"}
				#TODO bidouille
				url="#{Ruote::Sylrplm::ArWorkitem::SEP_URL}#{type_object}s"
				url+="#{Ruote::Sylrplm::ArWorkitem::SEP_URL}#{item.id}"
				label="#{type_object}#{Ruote::Sylrplm::ArWorkitem::SEP_TYPE_ITEM}#{item.ident}"
				LOG.debug(fname){"url=#{url} label=#{label}  fields=#{fields}"}
				new_param={url=>label}
				fields["params"][url]=label
				LOG.debug(fname){"fields[params] merge=#{fields["params"]}"}
				msg += " Field added:#{url} #{label}"
				ret+=1
			end
			ar_workitem.fields=fields
			LOG.info(fname){"apres add: fields=#{ar_workitem.fields}"}
			empty_clipboard_by_type(type_object)
		else
			msg += " Nothing to add:"+type_object
		end
		LOG.debug(fname){"#{type_object}=#{ret} msg=#{msg}"}
		ret
	end

	#
	def create_links(ar_workitem, wfid, relation_name)
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug(fname){"wfid=#{wfid} "}
		params = eval(ar_workitem.fields)["params"]
		LOG.debug(fname){"params=#{params}"}
		unless params.nil?
			params.keys.each do |url|
				v = params[url]
				LOG.debug(fname){"url=#{url} v=#{v}"}
				unless v.nil?
					sv = v.split(Ruote::Sylrplm::ArWorkitem::SEP_TYPE_ITEM)
					LOG.debug(fname){"sv=#{sv}"}
					if sv.size == 2
						sp = url.split(Ruote::Sylrplm::ArWorkitem::SEP_URL)
						LOG.debug(fname){"sp=#{sp} "}
						if sp.size == 3 && sp[0] != url
							cls = sp[1].chop
							id = sp[2]
							LOG.debug(fname){"class=#{cls} id=#{id} relation_name=#{relation_name}"}
							item = PlmServices.get_object(cls, id)
							LOG.debug(fname){"item=#{item}"}
							unless item.nil?
								relation = link_relation(ar_workitem, item, relation_name)
								unless relation.nil?
									link = link_object(ar_workitem, item, relation)
									if link.save
										LOG.info(fname){"save ok:link id="+link.id.to_s}
									else
										LOG.error(fname){"Error during saving the link :"+link.errors.inspect}
										link.errors.each do |err|
											ar_workitem.errors.add(:base, err)
										end
										msg="Link non sauve:#{link.errors.full_messages}'"
										raise PlmProcessException.new(msg, 10004)
									end
								else
									msg="No relation with name='#{relation_name}'"
									ar_workitem.errors.add(:base,msg)
									raise PlmProcessException.new(msg, 10005)
								end
							else
								msg="Object not found: '#{cls}.#{id}'"
								ar_workitem.errors.add(:base, msg)
								raise PlmProcessException.new(msg, 10006)
							end
						end
					end
				end
			end
		end
	end

	def link_relation(workitem, item, relation_name)
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug(fname) {"workitem=#{workitem} item=#{item} relation_name=#{relation_name}"}
		relation = Relation.by_values_and_name(workitem.modelname, item.modelname, workitem.modelname, item.typesobject.name, relation_name)
		if relation.nil?
			msg = "No relation '#{relation_name}' for workitem:#{workitem} and item:#{item}"
			LOG.debug(fname) {msg}
			workitem.errors.add(:base,msg)
		end
		relation
	end

	def link_object(workitem, item, relation)
		fname= "#{self.class.name}.#{__method__}"
		values = {}
		values["father_plmtype"]        = workitem.modelname
		values["child_plmtype"]         = item.modelname
		values["father_id"]             = workitem.id
		values["child_id"]              = item.id
		values["relation_id"]           = relation.id
		# en attendant mieux: user processus ou recup user en cours ...
		#user=User.find_by_name(PlmServices.get_property(:USER_ADMIN))
		#on prend celui du workitem (HistoryEntry)
		user=User.find_by_name(workitem.source)
		link = Link.new(values.merge(user: user))
	end

	#
	# find workitem, says 'unauthorized' if the user is attempting to
	# see / update an off-limit workitem
	#
	def find_ar_workitem(workitem)
		fname="WorkitemsController.#{__method__}"
		sleep 0.2
		ar_workitem = Ruote::Sylrplm::ArWorkitem.find_by_wfid(workitem.wfid)
		#TODOret=current_user.may_see?(ar_workitem) ? ar_workitem : nil unless ar_workitem.nil?
		LOG.debug(fname) {"wfid=#{workitem.wfid} ar_workitem=#{ar_workitem}"}
		ar_workitem
	end
end

