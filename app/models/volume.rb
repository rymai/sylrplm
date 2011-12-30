require 'rubygems'
require 'fog'
require 'classes/sylrplm_fog'

class Volume < ActiveRecord::Base
  include Models::SylrplmCommon
  #
  validates_presence_of :name, :protocole
  validates_format_of :name, :with =>/^([a-z]|[A-Z]|[0-9]||[.-])+$/
  validates_uniqueness_of :name
  #
  has_many :users
  has_many :datafiles
  #
  def validate
    puts "Volume.validate"
    errors.add_to_base I18n.t("valid_volume_directory_needed", :protocol=>protocole) if protocole != "fog" && directory.blank?
  end

  def initialize(params_volume=nil)
    super
    self.set_default_values(true) if params_volume.nil?
    self
  end

  def before_save
    dir = self.create_dir(directory_was)
    if dir.nil?
      self.errors.add_to_base I18n.t(:ctrl_object_not_created,:typeobj => I18n.t(:ctrl_volume), :ident=>self.name, :msg => nil)
    false
    else
    true
    end
  end

  def self.protocole_values
    ["fog", "local_vault"].sort
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
    if self.protocole == "fog"
    return self.protocole
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

  def create_dir_old(olddir)
    if (!File.exists?(self.directory))
      begin
        Dir.mkdir(self.directory)
      rescue
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
        rescue
          return nil
        end
      end
    end
  end

  def destroy_volume
    if !is_used
      if self.protocole == "fog"
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
    File.join(self.directory, self.name)
  end

  def self.get_conditions(filter)
    filter = filters.gsub("*","%")
    ret={}
    unless filter.nil?
      ret[:qry] = "name LIKE :v_filter or description LIKE :v_filter or directory LIKE :v_filter or protocole LIKE :v_filter"
      ret[:values]={:v_filter => filter}
    end
    ret
  #conditions = ["name LIKE ? or description LIKE ? or directory LIKE ? or protocole LIKE ?"
  end

private

  def _list_files_
    if self.protocole == "fog"
      ret="files stored in cloud by fog"
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
