#require 'lib/models/plm_object'
class Datafile < ActiveRecord::Base
  include Models::PlmObject
  include Models::SylrplmCommon

  validates_presence_of :ident , :typesobject
  validates_uniqueness_of :ident, :scope => :revision

  belongs_to :document
  belongs_to :typesobject
  belongs_to :volume
  belongs_to :owner,
    :class_name => "User"
  belongs_to :group
  belongs_to :projowner,
    :class_name => "Project"

  FILE_REV_DELIMITER="__"
  def self.create_new(params,user)
    if(params==nil)
      obj=new
      obj.set_default_values(true)
      obj.volume=user.volume
      obj.owner=user
      obj.group=user.group
      obj.projowner=user.project
      obj.revision="1"
    ret=true
    else
      parameters=params[:datafile]
      uploaded_file=parameters[:uploaded_file]
      #contournement pour faire le upload apres la creation pour avoir la revision dans
      #get_repository !!!!!!!!!!!!!!
      parameters.delete(:uploaded_file)
      parameters[:volume]=user.volume
      parameters[:owner]=user
      parameters[:group]=user.group
      parameters[:projowner]=user.project
      obj=new(parameters)
      if obj.save
        # on sauve le fichier maintenant et le tour est joue
        obj.create_dir
        if uploaded_file
          obj.update_attributes(:uploaded_file=>uploaded_file)
        #obj.save
        end
      end
    end
    puts "datafile.create_new:"+obj.inspect
    obj
  end

  def update_attributes_repos(params, user)
    parameters=params[:datafile]
    uploaded_file=parameters[:uploaded_file]
    parameters[:volume]=user.volume
    if(uploaded_file)
      parameters.delete(:uploaded_file)
      parameters[:revision]=self.revision.next
      self.update_attributes(parameters)
      self.create_dir
      self.update_attributes(:uploaded_file=>uploaded_file)
    else
      unless params[:restore_file].nil?
        puts "plm_object.update_attributes_repos:"+params[:restore_file]
        from_rev=Datafile.get_revision_from_file(params[:restore_file])
        if from_rev!=self.revision.to_s
          # on remet la revision demandee active en creant une nouvelle revision
          parameters[:revision]=self.revision.next
          parameters[:filename]=Datafile.get_filename_from_file(params[:restore_file])
          self.update_attributes(parameters)
          move_file(params[:restore_file])
        else
        self.update_attributes(parameters)
        end

      end
    end
  end

  def move_file(from)
    File.rename(File.join(get_dir_repository,from), get_repository)
  end

  def uploaded_file=(file_field)
    puts "plm_object.uploaded_file=:file_field="+file_field.inspect
    puts "plm_object.uploaded_file=:self="+self.inspect
    if (file_field!=nil && file_field!="" && file_field.original_filename!=nil && file_field.original_filename!="")
      content=file_field.read
      self.content_type=file_field.content_type.chomp
      self.filename=base_part_of(file_field.original_filename)
      write_file(content)
    end
  end

  def base_part_of(file_name)
    File.basename(file_name).gsub(/[^\w._-]/, '')
  end

  def get_dir_repository
    File.join self.volume.get_dir_name, self.class.name, self.ident
  end

  def get_repository
    # on prend le volume du fichier lui meme
    repos=get_dir_repository
    if(self.filename!=nil)
      repos=File.join(repos, get_filename_repository)
    end
    repos
  end

  def get_filename_repository
    unless self.revision.nil?
      FILE_REV_DELIMITER+self.revision.to_s+FILE_REV_DELIMITER+self.filename.to_s
    else
    self.filename.to_s
    end
  end

  def get_revisions_files
    ret=[]
    dir=get_dir_repository
    if File.exists?(dir)
      repos=get_filename_repository
      Dir.foreach(dir) { |file|
      #unless file == repos
        filename=file.split(FILE_REV_DELIMITER)[2]
        revision=file.split(FILE_REV_DELIMITER)[1]
        unless filename.nil? && revision.nil?
        #puts "plm_object.get_revisions;file="+file+" name="+filename.to_s+" rev="+revision.to_s
        ret<<file.to_s
        end
      #end
      }
    end
    #    if ret.length==0
    #      nil
    #    else
    #      ret
    #    end
    puts "plm_object.get_revisions:"+ret.length.to_s

    ret
  end

  def self.get_revision_from_file(_filename)
    _filename.split(FILE_REV_DELIMITER)[1]
  end

  def self.get_filename_from_file(_filename)
    _filename.split(FILE_REV_DELIMITER)[2]
  end

  def get_current_revision_file
    #puts "get_current_revision_file:"+self.revision.to_s+" filename="+self.filename.to_s
    ret=""
    unless self.revision.blank? && self.filename.blank?
      ret=FILE_REV_DELIMITER
      ret+=self.revision.to_s
      ret+=FILE_REV_DELIMITER
    ret+=self.filename.to_s
    end
    ret
  end

  def read_file_by_lines
    if File.exists?(get_repository)
      data=''
      f = File.open(get_repository, "r")
      f.each_line do |line|
        data += line
        puts "datafile.read_file a line"
      end
    else
      data=nil
    end
    data
  end

  def read_file
    if File.exists?(get_repository)
      data=''
      f = File.open(get_repository, "r")
      puts "debut lecture "+get_repository
      nc=0
      f.each_byte do |ch|
        data += ch.chr
        nc+=1
        #puts " "+nc.to_s
      end
      f.close
      puts "fin lecture "+get_repository
    else
      data=nil
    end
    data
  end
  
  def create_dir
    FileUtils.mkdir_p(get_dir_repository)
  end

  def write_file(content)
    f = File.open(get_repository, "w")
    puts "write_file:"+get_repository
    f.puts(content)
    f.close
  end

  def file_exists?
    File.exists?(get_repository)
  end

  def remove_file
    repos=get_repository
    if(repos!=nil)
      if (File.exists?(repos))
        begin
          File.unlink(repos)
        rescue
        return self
        end
      end
    else
      return nil
    end
    self
  end

  def delete
    self.remove_files
    self.destroy
  end

  def remove_files
    dir=get_dir_repository
    puts "datafile.remove_files:"+dir
    if File.exists?(dir)
      Dir.foreach(dir) { |file|
        repos=File.join(dir,file)
        puts "datafile.remove_files:"+repos
        if File.file?(repos)
          File.unlink(repos)
        end
      }
      Dir.rmdir(dir)
    end
  end

  def find_col_for(strcol)
    Sequence.find_col_for(self.class.name,strcol)
  end

  def self.get_conditions(filter)

    filter = filters.gsub("*","%")
    ret={}
    unless filter.nil?
      ret[:qry] = "ident LIKE :v_filter or revision LIKE :v_filter or updated_at LIKE :v_filter or "+qry_owner_id+" or "+qry_type+" or "+qry_volume
      ret[:values]={:v_filter => filter}
    end
    ret

  #["ident LIKE ? or "+qry_type+" or revision LIKE ? "+
  #  " or "+qry_owner_id+" or updated_at LIKE ? or "+qry_volume,

  end

end
