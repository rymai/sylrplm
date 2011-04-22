require 'ruote/participant'
require 'openwfe/participants/participants'

class Ruote::WfDocument

  include OpenWFE::LocalParticipant
  #
  # By default, returns false. When returning true the dispatch to the
  # participant will not be done in his own thread.
  def do_not_thread
    true
  end

  def initialize(work=nil, opts=nil)
    puts "WfTest.initialize*******************************************"
    puts "WfTest.initialize:opts="+opts.nil?.to_s
    puts "WfTest.initialize:work="+work.inspect
    @opts = opts
  end

  def consume(workitem)
    puts "WfTest.consume*******************************************"
    puts "WfTest.consume:workitem="+workitem.inspect
    puts "WfTest.consume:opts="+@opts.nil?.to_s
    puts "WfTest.consume:params="+workitem.attributes["params"].inspect
    unless workitem.attributes.nil?
      unless workitem.attributes["params"].nil?
        task = workitem.attributes["params"]["task"]
      end
    end
    puts "WfTest.consume:task="+task
    #puts "WfTest.consume:context="+@context.inspect
    fexpid=workitem.flow_expression_id
    puts "WfTest.consume:instance_id:"+fexpid.workflow_instance_id
    puts "WfTest.consume:expression_id:"+fexpid.expression_id
    #        arworkitem = OpenWFE::Extras::ArWorkitem.find_by_wfid_and_expid(
    #         fexpid.workflow_instance_id, fexpid.expression_id)
    arworkitem = OpenWFE::Extras::ArWorkitem.find_by_wfid(fexpid.workflow_instance_id)
    #puts "WfTest.consume:fields="+arworkitem.wi_fields.inspect
    #fields = arworkitem.field_hash #ActiveSupport::JSON.decode(arworkitem.wi_fields)
    #puts "WfTest.consume:fields="+fields.inspect
    if(task=="init")
      msg=add_objects(arworkitem, @favori_document, "document")
      msg+=add_objects(arworkitem, @favori_part, "part")
      msg+=add_objects(arworkitem, @favori_project, "project")
      puts "WfTest.consume:objects="+msg
    elsif(task=="promote")

      Link.find_childs("workitem",arworkitem,"document").each do |link|
        obj=Document.find(link.child_id)
        puts "WfTest.consume:promote:"+obj.to_s
        obj.promote
        obj.save
        puts "WfTest.consume:promote:"+obj.to_s
      end

      Link.find_childs("workitem",arworkitem,"part").each do |link|
        obj=Part.find(link.child_id)
        puts "WfTest.consume:promote:"+obj.to_s
        obj.promote
        obj.save
        puts "WfTest.consume:promote:"+obj.to_s
      end

      #      fields["/document/1"]=""
      #      arworkitem.replace_fields(fields)
      #      puts "WfTest.consume:fields="+arworkitem.field_hash.inspect
      #      arworkitem.save!

      #      params=workitem.attributes["params"]
      #      params["/document/1"]=""
      #      workitem.set_attribute("params",params)
      #      puts "WfTest.consume:workitem="+workitem.inspect
      puts "WfTest.consume:fin de promote"
    end
    reply_to_engine (workitem)
  end

  def add_objects(workitem, favori, type_object)
    unless favori.nil? || params[:relation].nil? || params[:relation][type_object].nil?
      relation=params[:relation][:document]
      ret=""
      #      puts "processes_controller.add_objects:workitem="+workitem.id.to_s+" rel="+relation.inspect+" favori="+favori.inspect
      favori.items.each do |item|
        link_=Link.create_new_byid("workitem", workitem.id, type_object, item.id, relation)
        link=link_[:link]
        if(link!=nil)
          if(link.save)
            ret += "\nLink added:"+type_object+":"+item.ident+"-"+relation+":"+link_[:msg]
          else
            ret += "\nLink not saved:"+type_object+":"+item.ident+"-"+relation+":"+link_[:msg]
          end
        else
          ret += "\nLink not added:"+type_object+":"+item.ident+"-"+relation
        end
      end
      #reset_favori_document
    else
      ret = "\nNothing to link:"+type_object
    end
    ret
  end
end
