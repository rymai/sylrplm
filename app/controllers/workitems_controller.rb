#
#  workitems_controller.rb
#  sylrplm
#
#  Created by Sylvère on 2012-02-04.
#  Copyright 2012 Sylvère. All rights reserved.
#
require 'openwfe/representations'
require 'ruote/sylrplm/workitems'
require 'classes/plm_services'

class WorkitemsController < ApplicationController
	include Controllers::PlmObjectControllerModule
	before_filter :authorize, :except => nil
	access_control(Access.find_for_controller(controller_name))
	# GET /workitems
	#  or
	# GET /workitems?q=:q || GET /workitems?query=:q
	#  or
	# GET /workitems?p=:p || GET /workitems?participant=:p
	#
	def index
		#puts "workitems_controller.index:params="+params.inspect
		@workitems=[]
		unless @current_user.nil?
			@query = params[:q] || params[:query]
			puts "workitems_controller.index:current_user.store_names="+@current_user.store_names.inspect
			if @query
				@workitems = Ruote::Sylrplm::ArWorkitem.search(@query, @current_user.is_admin? ? nil : @current_user.store_names)
			else
				opts = { :order => 'dispatch_time DESC' }
				opts[:conditions] = { :store_name => @current_user.store_names }
				opts[:page] = (params[:page].nil? ? PlmServices.get_property(:NB_ITEMS_PER_PAGE).to_i :  params[:page])
				@workitems = Ruote::Sylrplm::ArWorkitem.paginate_by_params(
				[
					# parameter_name[, column_name]
					'wfid',
					[ 'workflow', 'wfname' ],
					[ 'store', 'store_name' ],
					[ 'participant', 'participant_name' ]
				],
				params,
			opts)
			end
		end
		@workitems.each do |en|
			en.link_attributes={"relation"=>""}
		end
		##puts "workitems_controller.index:workitems="+@workitems.inspect
		# TODO : escape pagination for XML and JSON ??
		respond_to do |format|
			format.html
			# => app/views/workitems/index.html.erb
			format.json do
				render(:json => OpenWFE::Json.workitems_to_h(
          @workitems,
          :linkgen => linkgen).to_json)
			end
			format.xml do
				render(:xml => OpenWFE::Xml.workitems_to_xml(
          @workitems,
          :indent => 2, :linkgen => linkgen))
			end
		end
	end

	# GET /workitems/:wfid/:expid/edit
	#
	def edit
		fname= "workitems_controller.edit:"
		LOG.debug (fname){"params="+params.inspect}
		@workitem = find_ar_workitem
		@wi_links = @workitem.get_wi_links
		nb=0
		["document","part","project","customer","user"].each {|plm| nb+=add_objects(@workitem, plm) }
		if nb>0
		@workitem.save
		end
		return error_reply('no workitem', 404) unless @workitem

	# only responds in HTML...
	end

	# GET /workitems/:wfid/:expid
	#
	def show
		#    puts "workitems_controller.show:params="+params.inspect
		@workitem = find_ar_workitem
		@wi_links = @workitem.get_wi_links

		return error_reply('no workitem', 404) unless @workitem

		respond_to do |format|
			format.html # => app/views/show.html.erb
			format.json { render :json => OpenWFE::Json.workitem_to_h(
        @workitem, :linkgen => linkgen).to_json }
			format.xml { render :xml => OpenWFE::Xml.workitem_to_xml(
        @workitem, :indent => 2, :linkgen => linkgen) }
		end
	end

	# PUT /workitems/:wfid/:expid
	#
	def update
		name=self.class.name+"."+__method__.to_s+":"
		LOG.info (name) {"debut:params="+params.inspect}
		# select du ArWorkitem stocké en base ou sur fichier
		ar_workitem = find_ar_workitem
		return error_reply('no workitem', 404) unless ar_workitem
		#puts name+"ar_workitem="+ar_workitem.last_modified.to_s+":params="+ar_workitem.field_hash[:params].inspect
		# creation du InFlowWorkItem depuis le ar_workitem
		in_flow_workitem = ar_workitem.to_owfe_workitem
		#puts name+"in_flow_workitem="+in_flow_workitem.inspect
		# get WorkItem a partir des params du request
		workitem = parse_workitem
		#puts name+"workitem="+workitem.inspect
		workitem_ident = "#{in_flow_workitem.fei.wfid}/#{OpenWFE.to_uscores(in_flow_workitem.fei.expid)}"
		#puts name+"workitem_ident="+workitem_ident
		if store_name = params[:store_name]
			# delegation de la tache
			LOG.info{ name+"delegation:store="+store_name}
			ar_workitem.store_name = store_name
			ar_workitem.save!
			flash[:notice] = t(:ctrl_workitem_delegated, :ident => workitem_ident, :store => store_name)
			history_log(
        'delegated',
        :inflow => in_flow_workitem, :message => "wi delegated to '#{store_name}'")
		elsif params[:state] == 'proceeded'
			LOG.info {name+":debut proceeded:wfid="+params[:wfid]}
			in_flow_workitem.attributes = workitem.attributes
			LOG.debug name+"ar_workitem="+ar_workitem.inspect
			LOG.debug name+"in_flow_workitem="+in_flow_workitem.inspect
			respond_to do |format|
				begin
					RuotePlugin.ruote_engine.reply(in_flow_workitem)
					#
					# attente traitement par plm_participant
					#
					LOG.info (name){"avant sleep:participant_name=#{in_flow_workitem.participant_name} dispatch=#{ar_workitem.dispatch_time},modified=#{ar_workitem.last_modified}"}
					LOG.info (name){"avant sleep:ar_workitem=#{ar_workitem.inspect}"}
					LOG.info (name){"avant sleep:params="+ar_workitem.field_hash[:params].inspect}
					nb = 0
					arw = ar_workitem
					while nb < 7 and !arw.nil? and (arw.last_modified == ar_workitem.last_modified)
						#LOG.debug (name){" boucle #{nb}:#{arw.last_modified}"}
						sleep 0.4
						nb+=1
						arw = find_ar_workitem
					end
					#
					process = ruote_engine.process_status(params[:wfid])
					LOG.info {name+"apres sleep process="+process.to_s}
					unless process.nil?
					tree = process.current_tree
					else
						tree = nil
					end
					#
					#if ar_workitem.cancel?
					#puts name+"cancel"
					#
					opts = { :page => nil,
						:conditions => ["wfid = '"+params[:wfid]+"'"],
						:order => 'created_at DESC' }
					errors = OpenWFE::Extras::ProcessError.paginate(opts)
					errs = ""
					errors.each do  |er|
						e = er.as_owfe_error
						LOG.info (name) {":"+e.inspect}
						errs+="</br>"+e.message.to_s
						er.destroy
					end
					ok = false
					unless errs.empty?
						flash[:error] = t( :ctrl_workitem_canceled, :ident => workitem_ident)
						flash[:error]+= errs
						format.html { redirect_to :action => 'index'}
					#return error_reply(flash[:notice], 1001)
					else
					# recup du workitem sauve en base eventuellement modifie par le participant
						ar_workitem = find_ar_workitem
						return error_reply('no workitem', 404) unless ar_workitem
						LOG.info (name){"apres sleep:participant_name=#{in_flow_workitem.participant_name} dispatch=#{ar_workitem.dispatch_time},modified=#{ar_workitem.last_modified}"}
						LOG.info (name){"apres sleep:ar_workitem=#{ar_workitem.inspect}"}
						LOG.info (name){"apres sleep:params="+ar_workitem.field_hash[:params].inspect}
						#puts name+"wi_fields="+ar_workitem.field_hash.inspect
						#puts name+"activity="+ar_workitem.activity.inspect
						#puts name+"keywords="+ar_workitem.keywords.inspect
						# sauve history
						history_created = history_log('proceeded', :fei => in_flow_workitem.fei, :participant => in_flow_workitem.participant_name, :tree => tree.to_json, :message => ar_workitem.objects )
						unless history_created.nil?
							create_links(ar_workitem, params[:wfid], history_created)
							if history_created.errors.count == 0
								flash[:notice] = t(:ctrl_workitem_proceeded, :ident => workitem_ident)
							ok = true
							else
								flash[:error] = t( :ctrl_workitem_not_proceeded, :ident => workitem_ident, :msg => history_created.errors.inspect)
							###raise PlmProcessException.new("#{name}:error executing workitem #{workitem_ident}:#{history_created.errors.inspect}", 10002)
							end
						else
							flash[:error] = t( :ctrl_workitem_not_proceeded, :ident => workitem_ident)
						end
					end
					###sleep 0.1
					LOG.info (name){"ok=#{ok}, destroy de ArWorkitem.#{ar_workitem.id}"}
					Ruote::Sylrplm::ArWorkitem.destroy(ar_workitem.id)
					unless ok
						ruote_engine.cancel_process(params[:wfid])
						flash[:error] += "<br/>#{t(:ctrl_process_canceled, :ident => params[:wfid])}"
					###raise PlmProcessException.new("#{name}:error creating workitem #{workitem_ident}:#{link.errors.inspect}", 10001)
					#LOG.error (name) {flash[:notice]}
					end

					format.html { redirect_to :action => 'index'}
					format.xml  { render :xml => e, :status => :unprocessable_entity }
					#return error_reply(flash[:notice], 1003)

				rescue Exception => e

					flash[:error] = t(:ctrl_workitem_not_updated, :ident => "#{workitem_ident}:#{e}")
					LOG.error (name){in_flow_workitem.inspect}
					LOG.error (name){" error="+e.inspect}
					e.backtrace.each {|x| LOG.error x}
					format.html { redirect_to workitems_path }
					format.xml  { render :xml => e, :status => :unprocessable_entity }
				#return error_reply(flash[:notice], 1004)

				end
			end
		else
		# modification du contenu de la tache
		#puts name+"att="+workitem.attributes.inspect
			ar_workitem.replace_fields(workitem.attributes)
			history_log('saved', :inflow => in_flow_workitem, :message => 'wi saved')
			respond_to do |format|
				flash[:notice] = t(:ctrl_workitem_updated, :ident => workitem_ident)
				format.html { redirect_to :action => 'index'}
			end
		end
		LOG.info {name+"fin"}
	end

	def destroy
		fname = "WorkitemsController."+__method__.to_s+":"
		LOG.info (fname){"params="+params.inspect}
		ar_workitem = find_ar_workitem
		unless ar_workitem.nil?
			ar_workitem.destroy
			flash[:notice] = t(:ctrl_object_deleted, :typeobj => t(:ctrl_workitem), :ident => ar_workitem.ident)
		end
		respond_to do |format|
			format.html { redirect_to(workitems_url) }
			format.xml  { head :ok }
		end
	end

	###################
	# methodes privees
	###################
	private

	#
	# find workitem, says 'unauthorized' if the user is attempting to
	# see / update an off-limit workitem
	#
	def find_ar_workitem
		sleep 0.3
		ar_workitem = Ruote::Sylrplm::ArWorkitem.find_by_wfid_and_expid(
		params[:wfid], OpenWFE.to_dots(params[:expid])
		)
		ret=current_user.may_see?(ar_workitem) ? ar_workitem : nil unless ar_workitem.nil?
		LOG.debug {ret.inspect}
		ret
	end

	def add_objects(ar_workitem, type_object)
		name="WorkitemsController."+__method__.to_s+":"
		msg=""
		ret=0
		favori=@favori.get(type_object)
		if favori.count>0
			fields = ar_workitem.field_hash
			if fields == nil
				fields = {}
				fields["params"] = {}
			end
			#puts name+"favori="+favori.inspect
			#puts name+"avant add: workitem="+ar_workitem.id.to_s+ " fields="+fields.inspect
			favori.each do |item|
			#TODO bidouille
				url="/"+type_object+"s"
				url+="/"+item.id.to_s
				label=type_object+":"+item.ident
				#puts "workitems_controller.add_objects:url="+url+" label="+label+ " fields="+fields["params"].inspect
				fields["params"][url]=label
				msg += "\nField added:"+label
				ret+=1
			end
			ar_workitem.replace_fields(fields)
			#LOG.info (name){"apres add: fields="+ar_workitem.field_hash.inspect}
			empty_favori_by_type(type_object)
		else
			msg += "\nNothing to add:"+type_object
		end
		#puts  "workitems_controller.add_objects:"+type_object+"="+ret.to_s+":"+msg
		ret
	end

	#
	def create_links(cur_wi, wfid, history)
		fname="WorkitemsController."+__method__.to_s+":"
		#puts fname+"cur_wi="+cur_wi.id.to_s+":"+cur_wi.wfid.to_s+":"+cur_wi.expid.to_s
		params = cur_wi.field_hash[:params]
		LOG.debug (fname){"params="+params.inspect}
		unless params.nil?
			params.keys.each do |url|
				v = params[url]
				sv = v.split("#")
				if sv.size == 2
					sp = url.split("/")
					#puts fname+"sp "+sp.size.to_s+":"+sp[0].to_s
					if sp.size == 3 && sp[0] != url
						#puts fname+sp[1]+"("+sp[1].size.to_s+"):"+sp[2]
						cls = sp[1].chop
						id = sp[2]
						relation_name = sv[0]
						item = PlmServices.get_object(cls, id)
						unless item.nil?
							relation = link_relation(history, item, relation_name)
							unless relation.nil?
								link = link_object(history, item, relation)
								if link.save
									LOG.info(fname){"save ok:link id="+link.id.to_s}
								#{ link: link, msg: "ctrl_link_#{item.ident}" }
								else
									LOG.error(fname){"Error during saving the link :"+link.errors.inspect}
									##raise PlmProcessException.new(fname+"error save :"+link.errors.inspect, 10002)
									link.errors.each do |err|
										history.errors.add err
									end
								end
							else
								history.errors.add "Pas de relation de nom '#{relation_name}'"
							end
						else
							history.errors.add "Objet non trouve: '#{cls}.#{id}'"
						end
					end
				end
			end
		end

	end

	def link_relation (workitem, item, relation_name)
		fname = "WorkitemsController."+__method__.to_s+":"
		relation = Relation.by_values_and_name(workitem.model_name, item.model_name, workitem.model_name, item.typesobject.name, relation_name)
		if relation.nil?
			msg = "Pas de relation de nom '#{relation_name}' pour workitem:#{workitem} et item:#{item}"
			LOG.debug (fname) {msg}
		workitem.errors.add msg
		end
		relation
	end

	def link_object(workitem, item, relation)
		fname = "WorkitemsController."+__method__.to_s+":"
		values = {}
		values["father_plmtype"]        = workitem.model_name
		values["child_plmtype"]         = item.model_name
		values["father_typesobject_id"] = Typesobject.find_by_name(workitem.model_name).id
		values["child_typesobject_id"]  = item.typesobject_id
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
	# parsing incoming workitems
	#
	def parse_workitem
		begin
			ct = request.content_type.to_s
			# TODO : deal with Atom[Pub]
			return OpenWFE::Xml::workitem_from_xml(request.body.read) \
			if ct.match(/xml$/)
			return OpenWFE::Json.workitem_from_json(request.body.read) \
			if ct.match(/json$/)
			wi = OpenWFE::WorkItem.from_h(params)
			wi.attributes = ActiveSupport::JSON.decode(wi.attributes) \
			if wi.attributes.is_a?(String)
			wi
		rescue Exception => e
			LOG.error {"failed to parse workitem : #{e}"}
			nil
		end
	end

end

