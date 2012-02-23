#require 'lib/models/plm_object'
require 'openwfe/representations'
require 'ruote/part/local_participant'

class Part < ActiveRecord::Base
  include Ruote::LocalParticipant
  include Models::PlmObject
  include Models::SylrplmCommon
  validates_presence_of :ident, :designation
  validates_uniqueness_of :ident, :scope => :revision

  attr_accessor :link_attributes

  belongs_to :typesobject
  belongs_to :statusobject
  belongs_to :owner,
  :class_name => "User"
  belongs_to :group
  belongs_to :projowner,
    :class_name => "Project"
  #

  #has_and_belongs_to_many :documents, :join_table => "links",
  #:foreign_key => "father_id", :association_foreign_key => "child_id", :conditions => ["father_type='part' AND child_type='document'"]

  has_many :links_documents, :class_name => "Link", :foreign_key => "father_id", :conditions => ["father_plmtype='part' and child_plmtype='document'"]
  has_many :documents , :through => :links_documents

  has_many :links_workitems, :class_name => "Link", :foreign_key => "father_id", :conditions => ["father_plmtype='part' and child_plmtype='workitem'"]
  has_many :workitems , :through => :links_workitems

  has_many :links_parts, :class_name => "Link", :foreign_key => "father_id", :conditions => ["father_plmtype='part' and child_plmtype='part'"]
  has_many :parts , :through => :links_parts

  has_many :links_parts_up, :class_name => "Link", :foreign_key => "child_id", :conditions => ["father_plmtype='part' and child_plmtype='part'"]
  has_many :parts_up , :through => :links_parts_up

  has_many :links_projects, :class_name => "Link", :foreign_key => "child_id", :conditions => ["father_plmtype='project' and child_plmtype='part'"]
  has_many :projects , :through => :links_projects

  has_many :links_customers, :class_name => "Link", :foreign_key => "child_id", :conditions => ["father_plmtype='customer' and child_plmtype='part'"]
  has_many :customers , :through => :links_customers
  def to_s
    self.ident+"/"+self.revision+"-"+self.designation+"-"+self.typesobject.name+"-"+self.statusobject.name
  end

  def self.create_new(part,user)
    if(part!=nil)
      obj=Part.new(part)
    else
      obj=Part.new
    obj.set_default_values(true)
    end
    obj.statusobject=Statusobject.get_first("part")
    obj.owner=user
    obj.group=user.group
    obj.projowner=user.project
    #puts "part.create_new:"+p.inspect
    obj
  end

  def link_attributes=(att)
    @link_attributes = att
  end

  def link_attributes
    @link_attributes
  end

  # modifie les attributs avant edition
  def self.find_edit(object_id)
    obj=find(object_id)
    obj.edit
    obj
  end

  def self.get_types_part
    Typesobject.find(:all, :order=>"name",
    :conditions => ["object = 'part'"])
  end


  def self.get_conditions(filter)

    filter = filters.gsub("*","%")
    ret={}
    unless filter.nil?
      ret[:qry] = "ident LIKE :v_filter or "+qry_type+" or revision LIKE :v_filter or designation LIKE :v_filter or "+qry_status+
      " or "+qry_owner+" or date LIKE :v_filter "
      ret[:values]={:v_filter => filter}
    end
    ret
  #conditions = ["ident LIKE ? or "+qry_type+" or revision LIKE ? or designation LIKE ? or "+qry_status+
  #  " or "+qry_owner+" or date LIKE ? "
  end

end
