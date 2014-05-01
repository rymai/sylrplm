#
#  plm_participant.rb
#  sylrplm
#
#  Created by Sylvère on 2012-02-02.
#  Copyright 2012 Sylvère. All rights reserved.
#
############################################################################
# ATTENTION: ne pas utiliser le logger (LOG) ici car il n'est pas serialisable
# alors que cette classe est stockee par ruote
############################################################################
require 'ruote'
require 'ruote/sylrplm/plm_process_exception'

class Ruote::PlmParticipant
	include OpenWFE::LocalParticipant
	include Models::SylrplmCommon
	#
	# By default, returns false. When returning true the dispatch to the
	# participant will not be done in his own thread.
	#
	def do_not_thread
		fname="PlmParticipant.do_not_thread:"
		true
	end

	def initialize(work=nil, opts=nil)
		fname="PlmParticipant.initialize"
		puts fname+"opts="+opts.nil?.to_s+" work="+work.inspect
		@opts = opts
	end

	def consume(workitem)
		fname="PlmParticipant.consume:"
		puts fname+"debut *******************************************"
		#puts "PlmParticipant.consume:workitem="+workitem.inspect+" opts="+@opts.nil?.to_s
		#puts "PlmParticipant.consume:attributes="+workitem.attributes.inspect
		begin
			unless workitem.attributes.nil?
				unless workitem.attributes["params"].nil?
					task = get_param(workitem, "task")
					step = get_param(workitem, "step")
					relation_name = get_param(workitem, "relation", nil)
				end
			end
			msg="task(#{task}), step(#{step}), relation(#{relation_name})"
			puts fname+msg
			unless task.nil? || step.nil? || relation_name.nil?
				fexpid=workitem.flow_expression_id
				#puts fname+"instance_id:"+fexpid.workflow_instance_id
				#puts fname+"expression_id:"+fexpid.expression_id
				#Ruote::Sylrplm::ArWorkitem.all.each { |ar| puts ar.wfid }
				arworkitem = Ruote::Sylrplm::ArWorkitem.find_by_wfid(fexpid.workflow_instance_id)
				unless arworkitem.nil?
					unless step == "exec"
						#
						# tout sauf exec
						#
						check_objects(arworkitem, task, step, relation_name)
						reply_to_engine (workitem)
					else
					#
					# phase execution
					#
					#puts "PlmParticipant.consume:promote_exec:arworkitem_id="+arworkitem.id.to_s
						obj=nil
						# recherche des liens dont le pere est une tache ayant le meme wfid et ayant la relation requise
						#
						# liens dont le pere est une tache
						execute(task, Link.find_by_father_plmtype_(Ruote::Sylrplm::HistoryEntry.model_name), arworkitem, relation_name)
						reply_to_engine (workitem)
					end
				else
					msg=fname+"arworkitem("+fexpid.workflow_instance_id+") non trouve"
					raise PlmProcessException.new(msg, 10008)
				end
			else
				msg=fname+"task(#{task}) or step(#{step}) or relation(#{relation_name}) undefined"
				raise PlmProcessException.new(msg, 10009)
			end
		rescue Exception => e
			stack=""
			e.backtrace.each do |x|
				stack+= x+"\n"
			end
			puts fname+"exception:#{task}/#{step}:err=#{e}:stack=\n#{stack}"
			pe = get_error_journal.record_error(OpenWFE::ProcessError.new(fexpid, e.to_s, workitem, "fatal", stack))
			get_engine.replay_at_error(pe)
			get_engine.cancel_process(fexpid)
		end
		puts fname+"fin *******************************************"
	end

	private

	def check_objects(arworkitem, task, step, relation_name)
		fname="#{self.class.name}.#{__method__}"
		#prise en compte des objets transmis par le ar_workitem
		nb_applicable=0
		unless arworkitem.field_hash.nil?
			fields = arworkitem.field_hash
			LOG.info (fname) {"params avant replace=#{fields['params'].inspect}"}
			# voir workitems_controller pour la construction de ce parametre
			# /activity : rien a faire
			# /documents/3 : document(3)
			# apres split:
			# 0 = ""
			# 1 = plmtype de l'objet, par exemple "document"
			# 2 = id de l'objet, par exemple 3
			#puts "PlmParticipant.consume:url="+url
			fields["params"].keys.each do |url|
				v = fields["params"][url]
				sv = v.split("#")
				# url non encore traitee
				if sv.size == 1
					sp = url.split("/")
					#puts "PlmParticipant.consume:sp "+sp.size.to_s+":"+sp[0].to_s
					if sp.size == 3 && sp[0] != url
						#puts "PlmParticipant.consume:"+sp[1]+"("+sp[1].size.to_s+"):"+sp[2]
						cls=sp[1].chop
						id=sp[2]
						#rel=sp[3]
						#puts "v.consume:cls=#{cls.inspect} id=#{id.inspect}"
						#link_=add_object(arworkitem, cls, id, relation_name)
						v = relation_name+"#"+v
						# verif si on peut appliquer la methode sur l'objet
						if relation_name=="applicable"
							obj = get_object(cls, id)
							unless obj.nil?
								tst=task+"_by_action?"
								if obj.respond_to?(tst)
									if obj.send(tst)
										#tout est ok
										fields["params"][url] = v
										msg="Object #{url} could be #{task} by action flow"
										LOG.info (fname) {msg}
									nb_applicable+=1
									else
										msg="#{tst}=false on Object #{url} which could not be #{task} by action flow"
										LOG.info (fname) {msg}
									nb_applicable+=1
									end
								else
									msg="Check Method #{tst} is missing for Object #{url}"
									LOG.info (fname) {msg}
								nb_applicable+=1
								# ce n'est pas bloquant, on executera la fonction quand meme dans execute
								#raise PlmProcessException.new(msg, 10004)
								end
							else
								msg=fname+"Object #{url} does not exist"
								raise PlmProcessException.new(msg, 10005)
							end
						else
							fields["params"][url] = v
						nb_applicable+=1
						end
					end
				end
			# enlever le parametre pour ne pas le retrouver sur les taches suivantes
			###fields["params"].delete(url)
			end
		end
		LOG.info (fname) {"params apres replace=#{fields['params'].inspect} nb_applicable=#{nb_applicable}"}
		#
		# on doit avoir au moins un objet sur lequel s'applique le processus
		#
		if step!= "exec" && relation_name == "applicable" && nb_applicable==0
			msg = fname+":No applicable object for task(#{task}) and step(#{step}) and relation(#{relation_name})"
			raise PlmProcessException.new(msg, 10006)
		end
		arworkitem.replace_fields(fields) unless fields.nil?
	end

	def execute(task, alinks, arworkitem, relation_name)
		fname="PlmParticipant.execute:"
		#puts fname+arworkitem.wfid+":"+relation_name+":"+alinks.inspect
		if alinks.is_a?(Array)
		links = alinks
		else
		links = []
		links << alinks unless alinks.nil?
		end
		puts fname+arworkitem.wfid+":"+relation_name+":"+links.count.to_s+" links"
		links.each do |link|
		#puts fname+"link="+link.ident
			father = get_object(link.father_plmtype, link.father_id)
			#puts fname+"father="+father.inspect
			#puts fname+"father.wfid="+father.wfid + "==?" + arworkitem.wfid
			# bon wfid du pere
			unless father.nil? ||  father.wfid != arworkitem.wfid
				# bonne relation
				if link.relation.name == relation_name
					obj = get_object(link.child_plmtype, link.child_id)
					puts fname+"avant exec:obj="+obj.inspect
					unless obj.nil?
						objnew = obj.send(task)
						puts fname+"apres exec:objnew="+objnew.inspect
						unless objnew.nil?
							begin
								objnew.save
							rescue Exception => e
								msg=fname+"Object #{objnew} not saved:Error=#{e}"
								raise PlmProcessException.new(msg, 10010)
							end
						else
							msg=fname+"Object #{obj} not modified"
							raise PlmProcessException.new(msg, 10010)
						end

					else
						msg=fname+"Object #{url} does not exist"
						raise PlmProcessException.new(msg, 10011)
					end
				else
				#puts fname+"link.relation.name(#{link.relation.name}) != relation_name(#{relation_name})"
				end
			else
				if father.nil?
					puts fname+"father(#{father})=nil"
				else
					puts fname+"father.wfid(#{father.wfid}) != arworkitem.wfid(#{arworkitem.wfid})"
				end
			end
		end
	end

	def get_param(workitem, param, default=nil)
		ret=workitem.attributes["params"][param] unless workitem.attributes["params"][param].nil?
		if ret.nil?
		ret=default
		end
		ret
	end

end

