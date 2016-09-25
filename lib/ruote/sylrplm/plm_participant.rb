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
require 'ruote/sylrplm/sylrplm'

module  Ruote
	class PlmParticipant < Ruote::Participant
		include ::Models::SylrplmCommon
		#
		# By default, returns false. When returning true the dispatch to the
		# participant will not be done in his own thread.
		#
		def do_not_thread
			fname="#{self.class.name}.#{__method__}"
			LOG.debug(fname) {""}
			true
		end

		def initialize(work=nil, opts=nil)
			fname="#{self.class.name}.#{__method__}"
			LOG.debug(fname) {"opts=#{opts.nil?} work=#{work.inspect}"}
			@opts = opts
		end

		#rails2 def consume(workitem)
		def on_workitem
			fname="#{self.class.name}.#{__method__}"
			LOG.debug(fname) {"workitem=#{workitem.inspect}, opts?=#{@opts.nil?}"}
			LOG.debug(fname) {"workitem.h=#{workitem.to_h}"}
			process=RuoteKit.engine.process(workitem.wfid)
			begin
				unless workitem.nil?
					unless workitem.params.nil?
						task = get_param(workitem, "task")
						step = get_param(workitem, "step")
						relation_name = get_param(workitem, "relation", nil)
					end
				end
				msg="task(#{task}), step(#{step}), relation(#{relation_name})"
				LOG.debug(fname) {msg}
				unless task.nil? || step.nil? || relation_name.nil?
					fei=workitem.fei
					LOG.debug(fname) {"instance_id=#{fei.wfid} expression_id=#{fei.expid}"}
					arworkitem = Ruote::Sylrplm::ArWorkitem.find_by_wfid(workitem.wfid)
					LOG.debug(fname) {"arworkitem=#{arworkitem}"}
					unless workitem.nil?
						unless step == "exec"
							#
							# tout sauf exec
							#
							objs = check( task,  step, relation_name, arworkitem)
							create_link(arworkitem, objs, task, step, relation_name)
							reply_to_engine (workitem)
						else
						#
						# phase execution
						#
							obj=nil
							# old: recherche des liens dont le pere est une tache ayant le meme wfid et ayant la relation requise
							#
							# liens dont le pere est une tache
							objs = execute( task,  arworkitem)
							create_link(arworkitem, objs, task, step, relation_name)
							reply_to_engine(workitem)
						end
					else
						msg="#{fname}: arworkitem(#{workitem.wfid}) non trouve"
						raise PlmProcessException.new(msg, 10008)
					end
				else
					msg="#{fname}: task(#{task}) or step(#{step}) or relation(#{relation_name}) undefined"
					raise PlmProcessException.new(msg, 10009)
				end
			rescue Exception => e
				stack=""
				e.backtrace.each do |x|
					stack+= x+"\n"
				end
				LOG.debug(fname) {"exception:#{task}/#{step}:err=#{e}:stack=\n#{stack}"}
				process_error = Ruote::ProcessError.new({:wfid=>process.wfid, :fei=>fei, :message=>e.to_s, :workitem=>workitem, :klass=>"fatal", :msg=>stack})
			arworkitem.error=e.message unless arworkitem.nil?
			end
			arworkitem.save
			LOG.debug(fname) {"fin fin arworkitem=#{arworkitem}  id=#{arworkitem.id}"}
		end

		private

		def check(task,  step, relation_name, arworkitem)
			fname="#{self.class.name}.#{__method__}"
			objects=get_objects_in_workitem(arworkitem)
			ret=[]
			objects.each do |obj|
				LOG.debug(fname) {"avant check: obj=#{obj} task=#{task}"}
				unless obj.nil?
					byaction=obj.send("#{task}_by_action?")
					unless byaction
						msg=fname+"Object #{obj} can't be #{task} by action"
						raise PlmProcessException.new(msg, 10001)
					else
					ret<<obj
					end
				end
			end
			ret
		end

		def execute( task, arworkitem)
			fname="#{self.class.name}.#{__method__}"
			objects=get_objects_in_workitem(arworkitem)
			ret=[]
			objects.each do |obj|
				LOG.debug(fname) {"avant exec:obj=#{obj} task=#{task}"}
				unless obj.nil?
					objnew = obj.send(task)
					LOG.debug(fname) {"apres exec:objnew=#{objnew}"}
					unless objnew.nil?
						begin
							st=objnew.save
							if st
							ret<<objnew
							else
								msg=fname+"Object #{objnew} not saved"
								raise PlmProcessException.new(msg, 10012)
							end
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
			end
			ret
		end

		def create_link( arworkitem, objects, task, step, relation_name)
			fname="#{self.class.name}.#{__method__}"
			LOG.debug(fname) {"arworkitem=#{arworkitem} objects=#{objects} task=#{task} step=#{step} relation_name=#{relation_name}"}
			ret=[]
			link=nil
			objects.each do |item|
				link=nil
				relation = link_relation(arworkitem, item, relation_name)
				unless relation.nil?
					link = link_object(arworkitem, item, relation)
					if link.save
						LOG.info(fname){"save ok:link id=#{link.id}"}
					else
						LOG.error(fname){"Error during saving the link:#{link.errors.full_messages}"}
						raise PlmProcessException.new(link.errors.full_messages, 10005)
					end
				else
					msg=fname+" No relation with name='#{relation_name}'"
					LOG.debug(fname) {msg}
					raise PlmProcessException.new(msg, 10005)
				end
				ret<<link
			end
			LOG.info(fname){"links crees=#{ret}"}
			ret
		end

		def link_relation(arworkitem, item, relation_name)
			fname="#{self.class.name}.#{__method__}:"
			LOG.debug(fname) {"arworkitem=#{arworkitem} item=#{item} relation_name=#{relation_name}"}
			relation = Relation.by_values_and_name(arworkitem.modelname, item.modelname, arworkitem.modelname, item.typesobject.name, relation_name)
			if relation.nil?
				msg = fname+" No relation '#{relation_name}' for workitem:#{arworkitem} and item:#{item}"
				LOG.debug(fname) {msg}
				raise PlmProcessException.new(msg, 10005)
			end
			relation
		end

		def link_object(arworkitem, item, relation)
			fname="#{self.class.name}.#{__method__}"
			LOG.debug(fname) {"arworkitem=#{arworkitem} item=#{item} relation=#{relation}"}
			values = {}
			values["father_plmtype"]        = arworkitem.modelname
			values["child_plmtype"]         = item.modelname
			values["father_id"]             = arworkitem.id
			values["child_id"]              = item.id
			values["relation_id"]           = relation.id
			# en attendant mieux: user processus ou recup user en cours ...
			#user=User.find_by_name(PlmServices.get_property(:USER_ADMIN))
			#on prend celui du workitem (HistoryEntry)
			user=User.find(arworkitem.owner_id)
			link = Link.new(values.merge(user: user))
			LOG.debug(fname) {"link=#{link}"}
			link
		end

		def get_param(workitem, param, default=nil)
			fname="#{self.class.name}.#{__method__}"
			ret=workitem.params[param] unless workitem.params[param].nil?
			if ret.nil?
			ret=default
			end
			ret
		end

		def get_objects_in_workitem(arworkitem)
			fname="#{self.class.name}.#{__method__}"
			fields = eval(arworkitem.fields)
			LOG.info(fname) {"params avant analyse=#{fields['params']}"}
			ret=[]
			fields["params"].keys.each do |url|
				LOG.info(fname) {"params:url=#{url}"}
				urlvalue = fields["params"][url]
				LOG.debug(fname){"url=#{url} urlvalue=#{urlvalue}"}
				unless urlvalue.nil?
					sv = urlvalue.split(Ruote::Sylrplm::ArWorkitem::SEP_TYPE_ITEM)
					if sv.size == 2
						sp = url.split(Ruote::Sylrplm::ArWorkitem::SEP_URL)
						if sp.size == 3 && sp[0] != url
							LOG.info(fname) {"sp1=#{sp[1]}(#{sp[1].size}):#{sp[2]}"}
							cls=sp[1].chop
							id=sp[2]
							LOG.debug(fname){"class=#{cls} id=#{id}"}
							obj = get_object(cls, id)
						ret<<obj
						end
					end
				end
			end
			LOG.debug(fname){"ret=#{ret} "}
			ret
		end

	end
end