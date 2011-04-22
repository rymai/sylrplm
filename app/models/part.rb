#require 'lib/models/plm_object'
require 'openwfe/representations'
require 'ruote/part/local_participant'
class Part < ActiveRecord::Base
  include Ruote::LocalParticipant
  include Models::PlmObject
  include Models::SylrplmCommon
  validates_presence_of :ident, :designation
  validates_uniqueness_of :ident, :scope => :revision

  belongs_to :typesobject
  belongs_to :statusobject
  belongs_to :owner,
  :class_name => "User"
  #

  #has_and_belongs_to_many :documents, :join_table => "links",
  #:foreign_key => "father_id", :association_foreign_key => "child_id", :conditions => ["father_object='part' AND child_object='document'"]

  has_many :links_documents,:class_name => "Link", :foreign_key => "father_id", :conditions => ["father_object='part' and child_object='document'"]
  has_many :documents , :through => :links_documents

  has_many :links_workitems,:class_name => "Link", :foreign_key => "father_id", :conditions => ["father_object='part' and child_object='workitem'"]
  has_many :workitems , :through => :links_workitems

  has_many :links_parts,:class_name => "Link", :foreign_key => "father_id", :conditions => ["father_object='part' and child_object='part'"]
  has_many :parts , :through => :links_parts

  has_many :links_projects,:class_name => "Link", :foreign_key => "father_id", :conditions => ["father_object='project' and child_object='part'"]
  has_many :projects , :through => :links_projects

  has_many :links_customers,:class_name => "Link", :foreign_key => "father_id", :conditions => ["father_object='customer' and child_object='part'"]
  has_many :customers , :through => :links_customers
  def to_s
    self.ident+"/"+self.revision+"-"+self.designation+"-"+self.typesobject.name+"-"+self.statusobject.name
  end

  def self.create_new(part,user)
    if(part!=nil)
      p=Part.new(part)
    else
      p=Part.new
      p.set_default_values(true)
    end
    p.statusobject=Statusobject.get_first("part")
    p.owner=user
    puts "part.create_new:"+p.inspect
    p
  end

  # modifie les attributs avant edition
  def self.find_edit(object_id)
    obj=find(object_id)
    obj.edit
    obj
  end

  def frozen?
    !(self.statusobject.nil? || Statusobject.get_last("part").nil?) &&
    self.statusobject.rank == Statusobject.get_last("part").rank
  end

  # a valider si avant dernier status
  def is_to_validate
    if(self.statusobject!=nil && Statusobject.get_last("part")!=nil)
      if(self.statusobject.rank == Statusobject.get_last("part").rank-1)
        true
      else
        false
      end
    else
      false
    end
  end

  def self.get_types_part
    Typesobject.find(:all, :order=>"name",
    :conditions => ["object = 'part'"])
  end

  def self.find_all
    find(:all, :order=>"ident")
  end

  def self.find_others(part_id)
    find(:all,
    :conditions => ["id != #{part_id}"],
    :order=>"ident")
  end

  def add_documents_from_favori(favori)
    favori.items.each do |item|
      documents << item
    end
  end

  def remove_documents()
    documents =nil
  end

  def remove_document(document)
    documents.delete( document)
  end

  def add_projects_from_favori(favori)
    favori.items.each do |item|
      projects << item
    end
  end

  def remove_projects()
    projects =nil
  end

  def remove_project(item)
    projects.delete( item)
  end

  def find_last_revision(object)
    Part.find(:last, :order=>"revision ASC",  :conditions => ["ident = '#{object.ident}'"])
  end

  def promote
    self.statusobject=Statusobject.find_next("part",self.statusobject)
    self
  end

  def self.get_conditions(filter)
    filter=filter.gsub("*","%")
    conditions = ["ident LIKE ? or "+qry_type+" or revision LIKE ? or designation LIKE ? or "+qry_status+
      " or "+qry_owner+" or date LIKE ? ",
      filter, filter,
      filter, filter,
      filter, filter,
      filter ] unless filter.nil?
  end

  def consume(workitem)
    puts self.Class.name+".consume"
    h = workitem.to_h
    h['fei'] = workitem.fei.sid
    File.open("worklist/workitem_#{workitem.fei.sid}.yaml", wb) do |f|
      f.puts(h.to_yaml)
    end
    reply_to_engine(workitem)
  end

  def cancel(fei, flavour)
    FileUtils.rm("worklist/workitem_#{fei.sid}.yaml")
  end

  # A method called by external systems when they're done with a workitem
  # hash, they hand it back to the engine via this method.
  #
  def self.reply(workitem_h)
    FileUtils.rm("worklist/workitem_#{workitem_h['fei']}.yaml")
    reply_to_engine(workitem)
  end

end
