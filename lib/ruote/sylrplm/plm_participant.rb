#require 'ruote/participant'
#require 'openwfe/participants/participants'
#require 'openwfe/extras/participants/ar_participants'

class Ruote::PlmParticipant
  include OpenWFE::LocalParticipant
  include Models::SylrplmCommon
  #
  # By default, returns false. When returning true the dispatch to the
  # participant will not be done in his own thread.
  def do_not_thread
    true
  end

  def initialize(work=nil, opts=nil)
    puts "PlmParticipant.initialize*******************************************"
    puts "PlmParticipant.initialize:opts="+opts.nil?.to_s+" work="+work.inspect
    @opts = opts
  end

  def consume(workitem)
    puts "PlmParticipant.consume:debut *******************************************"
    #puts "PlmParticipant.consume:workitem="+workitem.inspect+" opts="+@opts.nil?.to_s
    #puts "PlmParticipant.consume:attributes="+workitem.attributes.inspect
    begin
      unless workitem.attributes.nil?
        unless workitem.attributes["params"].nil?
          task = get_param(workitem, "task")
          step = get_param(workitem, "step")
          relation_name = get_param(workitem, "relation", get_default_relation(task, step))
        end
      end
      puts "PlmParticipant.consume:task="+task.to_s+" step="+step.to_s
      unless task.nil? || step.nil?
        fexpid=workitem.flow_expression_id
        #puts "PlmParticipant.consume:instance_id:"+fexpid.workflow_instance_id
        #puts "PlmParticipant.consume:expression_id:"+fexpid.expression_id
        arworkitem = Ruote::Sylrplm::ArWorkitem.find_by_wfid(fexpid.workflow_instance_id)
        unless step == "exec" 
          #prise en compte des objets transmis par le ar_workitem
          unless arworkitem.field_hash.nil?
            params= arworkitem.field_hash["params"]
            puts "PlmParticipant.consume:params="+params.inspect
            params.keys.each do |k|
            # /activity : rien a faire
            # /documents/3 : document(3)
            # apres split:
            # 0 = ""
            # 1 = document: modele
            # 2 = 3: id du document
              #puts "PlmParticipant.consume:k="+k
              sp = k.split("/")
              #puts "PlmParticipant.consume:sp "+sp.size.to_s+":"+sp[0].to_s
              if sp.size==3 && sp[0]!=k
                #puts "PlmParticipant.consume:"+sp[1]+"("+sp[1].size.to_s+"):"+sp[2]
                cls=sp[1].chop
                id=sp[2]
                #rel=sp[3]
                #puts "v.consume:cls=#{cls.inspect} id=#{id.inspect}"
                link_=add_object(arworkitem, cls, id, relation_name)
                #puts "PlmParticipant.consume:cls="+cls.to_s+" id="+id.to_s+" link="+link_.inspect
                if link_[:link].nil?
                  puts "PlmParticipant.consume: lien non cree:"+link_[:mg]
                  get_engine.cancel_process(fexpid)
                end
              end
            end
          end
          reply_to_engine (workitem)
        else 
          # exec
          #puts "PlmParticipant.consume:promote_exec:arworkitem_id="+arworkitem.id.to_s
          obj=nil
          Link.find_childs(arworkitem).each do |link|
            obj=get_object(link.child_plmtype, link.child_id)
            #puts "PlmParticipant.consume avant exec:"+task.to_s+"/"+step.to_s+":obj="+obj.to_s
            unless obj.nil?
              obj.method(task).call
              obj.save
            end
          end
          Link.find_childs_with_father_type("history_entry", arworkitem).each do |link|
            obj=get_object(link.child_plmtype, link.child_id)
            #puts "PlmParticipant.consume avant exec:"+task.to_s+"/"+step.to_s+":obj="+obj.to_s
            unless obj.nil?
              obj.method(task).call
              obj.save
            end
          end
          #puts "PlmParticipant.consume apres exec:"+task.to_s+"/"+step.to_s+":obj="+obj.to_s
          reply_to_engine (workitem)
        #else
        #  puts "PlmParticipant.consume: pas de tache ou tache/etape "+task.to_s+"/"+step+" non reconnue => abandon"
        #  get_engine.cancel_process(fexpid)
        end
      end
    rescue Exception => e
      puts "PlmParticipant.consume:exception:"+task.to_s+"/"+step+":err="+e.to_s+" sur "+obj.inspect
      e.backtrace.each {|x| puts x}
      get_engine.cancel_process(fexpid)
    end
    puts "PlmParticipant.consume:fin *******************************************"
  end

  private

  def add_object(workitem, type_object, item_id, relation_name)
    item = get_object(type_object, item_id)
    relation = Relation.by_values(workitem.model_name, item.model_name, "workitem", type_object, relation_name)
    puts "PlmParticipant.add_object:workitem="+workitem.id.to_s+" relation="+relation.id.to_s
    link_={:link=>nil, :msg=>nil}
    unless relation.nil?
      values={}
      values["father_plmtype"] = workitem.model_name
      values["child_plmtype"]  = item.model_name
      values["father_type_id"] = Typesobject.find_by_name(workitem.model_name).id
      values["child_type_id"]  = item.typesobject_id
      values["father_id"]      = workitem.id
      values["child_id"]       = item.id
      values["relation_id"]    = relation.id
      link_= Link.create_new_by_values(values)
    else
      link[:msg] = "Pas de relation de nom "+relation_name
    end
    unless link_[:link].nil?
      if link_[:link].save
        puts  "PlmParticipant.add_object:save ok:"+link_[:link].id.to_s
      else
        puts  "PlmParticipant.add_object:error save :"+link_[:link].errors.inspect
      end
    else
      puts  "PlmParticipant.add_object:error create:"+link_[:link].inspect
    end
    link_
  end

  def get_default_relation(task, step)
    ret = case step
    when "init" then "applicable"
    else "reference"
    end
    #puts  "PlmParticipant.get_default_relation:"+task.to_s+"."+step.to_s+"="+ret.to_s
    ret
  end

  def get_param(workitem, param, default=nil)
    ret=workitem.attributes["params"][param] unless workitem.attributes["params"][param].nil?
    if ret.nil?
    ret=default
    end
    ret
  end

end
