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
    name="PlmParticipant.do_not_thread:"
    puts name
    true
  end

  def initialize(work=nil, opts=nil)
    puts "PlmParticipant.initialize:opts="+opts.nil?.to_s+" work="+work.inspect
    @opts = opts
  end

  def consume(workitem)
    name="PlmParticipant.consume:"
    puts name+"debut *******************************************"
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
      puts name+"task="+task.to_s+" step="+step.to_s
      unless task.nil? || step.nil?
        fexpid=workitem.flow_expression_id
        puts name+"instance_id:"+fexpid.workflow_instance_id
        puts name+"expression_id:"+fexpid.expression_id
        Ruote::Sylrplm::ArWorkitem.all.each { |ar| puts ar.wfid }
        arworkitem = Ruote::Sylrplm::ArWorkitem.find_by_wfid(fexpid.workflow_instance_id)
        unless arworkitem.nil?
          unless step == "exec"
            #
            # tout sauf exec
            #
            #prise en compte des objets transmis par le ar_workitem
            unless arworkitem.field_hash.nil?
              fields = arworkitem.field_hash
              puts name+"arworkitem avant replace params="+fields["params"].inspect
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
                    fields["params"][url] = v
                  end
                end
              # enlever le parametre pour ne pas le retrouver sur les taches suivantes
              ###fields["params"].delete(url)
              end
              puts name+"arworkitem apres replace params="+fields["params"].inspect
            arworkitem.replace_fields(fields)
            end
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
          #else
          #  puts name+"pas de tache ou tache/etape "+task.to_s+"/"+step+" non reconnue => abandon"
          #  get_engine.cancel_process(fexpid)
          end
        else
          msg=name+"arworkitem("+fexpid.workflow_instance_id+") non trouve"
          raise PlmProcessException.new(msg, 10004)
        end
      end
    rescue Exception => e
      puts name+"exception:"+task.to_s+"/"+step+":err="+e.to_s
      stack=""
      e.backtrace.each do |x|
        stack+= x+"\n"
      end
      puts name+"stack="+stack
      pe = get_error_journal.record_error(OpenWFE::ProcessError.new(fexpid, e.to_s, workitem, "fatal", stack))
      get_engine.replay_at_error(pe)
      get_engine.cancel_process(fexpid)
    end
    puts name+"fin *******************************************"
  end

  private

  def execute(task, alinks, arworkitem, relation_name)
    name="PlmParticipant.execute:"
    #puts name+arworkitem.wfid+":"+relation_name+":"+alinks.inspect
    if alinks.is_a?(Array)
    links = alinks
    else
    links = []
    links << alinks unless alinks.nil?
    end
    #puts name+arworkitem.wfid+":"+relation_name+":"+links.count.to_s+" links"
    links.each do |link|
      #puts name+"link="+link.ident
      father = get_object(link.father_plmtype, link.father_id)
      #puts name+"father="+father.wfid + "==" + arworkitem.wfid
      # bon wfid du pere
      unless father.nil? ||  father.wfid != arworkitem.wfid
        # bonne relation
        if link.relation.name == relation_name
          obj = get_object(link.child_plmtype, link.child_id)
          #puts name+"avant exec:obj="+obj.inspect
          unless obj.nil?
            #obj.promote
            #obj.method(task).call
            obj.send(task)
            obj.save
            LOG.info{name+"apres exec:obj="+obj.inspect}
          end
        end
      end
    end
  end

  def add_object_obsolete(workitem, type_object, item_id, relation_name)
    item = get_object(type_object, item_id)
    relation = Relation.by_values_and_name(workitem.model_name, item.model_name, "ar_workitem", type_object, relation_name)
    #puts "PlmParticipant.add_object:workitem="+workitem.id.to_s+" relation="+relation.id.to_s
    #puts "PlmParticipant.add_object:workitem="+workitem.inspect
    puts "PlmParticipant.add_object:relation="+relation.ident
    link_={:link=>nil, :msg=>nil}
    unless relation.nil?
      values={}
      values["father_plmtype"] = workitem.model_name
      values["child_plmtype"]  = item.model_name
      values["father_type_id"] = Typesobject.find_by_name("ar_workitem").id
      values["child_type_id"]  = item.typesobject_id
      values["father_id"]      = workitem.id
      values["child_id"]       = item.id
      values["relation_id"]    = relation.id
      link_= Link.create_new_by_values(values, nil)
      puts "PlmParticipant.add_object:link_="+link_.inspect
    else
      link_[:msg] = "PlmParticipant.add_object:Pas de relation de nom "+relation_name
      raise PlmProcessException.new(
      "Pas de relation de nom '"+relation_name+"'", 10001)
    end
    unless link_[:link].nil?
      #unless link_[:link].exists?
      if link_[:link].save
        puts  "PlmParticipant.add_object:save ok:link id="+link_[:link].id.to_s
      else
        raise PlmProcessException.new(
      "PlmParticipant.add_object:error save :"+link_[:link].errors.inspect, 10002)
      end
    #else
    #  puts  "PlmParticipant.add_object:link existant deja :"+link_[:link].inspect
    #end
    else
      puts  "PlmParticipant.add_object:error create:link="+link_.inspect
      raise PlmProcessException.new(
      "PlmParticipant.add_object:error create:link="+link_.inspect, 10003)
    end
    link_
  end

  def get_default_relation(task, step)
    ret = case step
    when "review" then "reference"
    else "applicable"
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

