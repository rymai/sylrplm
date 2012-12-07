require 'rubygems'
require 'fog'
require 'classes/sylrplm_fog'

class Volume < ActiveRecord::Base
  include Models::SylrplmCommon

  validates_presence_of :name, :protocol
  validates_format_of :name, :with =>/^([a-z]|[A-Z]|[0-9]||[.-])+$/
  validates_uniqueness_of :name

  has_many :users
  has_many :datafiles

  def validate
    puts "Volume.validate"
    errors.add_to_base I18n.t("valid_volume_directory_needed", :protocol=>protocol) if protocol != "fog" && directory.blank?
  end

  def initialize(params_volume=nil)
    super
    if params_volume.nil?
      self.directory = SYLRPLM::VOLUME_DIRECTORY_DEFAULT
      self.set_default_values(true)
    end
    self
  end

  def before_save
    self.set_directory(directory_was)
  end

  def set_directory(directory_was=nil)
    #recherche des repertoires fog
    if self.protocol == "fog"
      self.directory="sylrplm-"+Rails.env.slice(0,4)+"-"+Time.now.to_i.to_s
    end
    dir = self.create_dir(directory_was)
    if dir.nil?
      self.errors.add_to_base I18n.t(:ctrl_object_not_created,:typeobj => I18n.t(:ctrl_volume), :ident=>self.name, :msg => nil)
    false
    else
    true
    end
  end

  def self.protocol_values
    ["fog", "file_system"].sort
  end

  def self.find_all
    find(:all, :order=>"name")
  end

  def self.find_first
    find(:first, :order=>"name")
  end

  def is_used
    self.users.count >0 || self.datafiles.count >0
  end

  def create_dir(olddir)
    puts "Volume.create_dir"+self.inspect
    if self.protocol == "fog"
    return self.protocol
    else
      if (!File.exists?(self.directory))
        begin
          Dir.mkdir(self.directory)
        rescue Exception => e
          self.errors.add_to_base e.inspect
          return nil
        end
      end
      if(olddir!=nil)
        dirfrom=File.join(olddir,self.name)
        if(File.exists?(dirfrom))
          dirto=self.directory
          catto=File.join(olddir,dirto)
          if(catto!=dirto)
            begin
              FileUtils.mv(dirfrom, dirto)
              dir=File.join(self.directory,self.name)
              dir
            rescue
              return nil
            end
          end
        else
          return nil
        end
      else
      #1ere creation
        dir=File.join(self.directory,self.name)
        if !File.exists?(dir)
          begin
            Dir.mkdir(dir)
            return dir
          rescue Exception => e
            obj.errors.add_to_base e.inspect
            return nil
          end
        end
      end
    end
  end

  def destroy_volume
    if !is_used
      if self.protocol == "fog"
      ret=self.destroy
      else
        stdel=self.destroy
        if File.exists? self.dir_name
          begin
            strm=FileUtils.remove_dir self.dir_name
          rescue Exception => e
          #e.backtrace.each {|x| puts x}
            puts "volume.destroy_volume:error="+e.inspect
            self.errors.add_to_base I18n.t(:check_volume_no_rmdir, :name => self.name, :dir => self.directory)
          strm=false
          end
        else
          self.errors.add_to_base I18n.t(:check_volume_no_dir, :name => self.name, :dir => self.directory)
        #le repertoire n'existe pas, c'est pas grave
        strm=true
        end
      ret=stdel && strm
      end
    else
      self.errors.add_to_base I18n.t(:check_volume_is_used, :ident=>self.name)
    ret=false
    end
    puts "volume._destroy_volume_:ret="+ret.to_s+" stdel="+stdel.to_s+" strm="+strm.to_s
    ret
  end

  def list_files
    _list_files_
  end

  def dir_name
    self_dir=self.directory
    unless self_dir.nil?
      ret=File.join(self_dir, self.name)
    else
    ret=self.name
    end
    #puts "Volume.dir_name:"+ret
    ret
  end

  def self.get_conditions(filter)
    filter = filters.gsub("*","%")
    ret={}
    unless filter.nil?
      ret[:qry] = "name LIKE :v_filter or description LIKE :v_filter or directory LIKE :v_filter or protocol LIKE :v_filter"
      ret[:values]={:v_filter => filter}
    end
    ret
  #conditions = ["name LIKE ? or description LIKE ? or directory LIKE ? or protocol LIKE ?"
  end

  private

  def _list_files_
    if self.protocol == "fog"
      ret="files are stored in cloud by fog"
    else
      dir=File.join(self.directory,self.name)
      ret=""
      if(File.exists?(dir))
        Dir.foreach(dir) { |objectdir|
          if(objectdir!="." && objectdir!="..")
            dirobject=File.join(dir,objectdir)
            if(File.directory?(dirobject))
              Dir.foreach(dirobject) { |iddir|
                if(iddir!="." && iddir!="..")
                  dirid=File.join(dirobject,iddir)
                  ret+="\ndirid="+iddir+"="+dirid
                  if(File.directory?(dirid))
                    files=Dir.entries(dirid)
                    if(files.size>2)
                      ret+=":nb="+files.size.to_s+":id="+iddir
                      for f in  files
                        ret+=":"+f
                      end

                    end
                  else
                    ret+="\nbad file:"+dirid
                  end
                end
              }
            else
              ret+="\nbad file:"+dirobject
            end
          end
        }
      ret
      end
    end
  end

end
