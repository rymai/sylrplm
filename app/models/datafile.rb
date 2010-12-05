#require 'lib/models/plm_object'
class Datafile < ActiveRecord::Base
  include Models::PlmObject
  include Models::SylrplmCommon
  
  validates_presence_of :ident , :typesobject
  validates_uniqueness_of :ident, :scope => :revision
  
  belongs_to :typesobject
  belongs_to :volume
  belongs_to :owner,
    :class_name => "User",
    :foreign_key => "owner_id" 
  
  def self.create_new(params,user)
    #puts "datafile.create_new:user="+user.inspect
    if(params==nil)   
      datafile=new 
      Sequence.set_default_values(datafile, self.name,true)
      datafile.volume=user.volume
      datafile.owner=user
      datafile.revision="1"
      ret=true
    else
      parameters=params[:datafile]
      puts "datafile.create_new:param="+params.inspect
      uploaded_file=parameters[:uploaded_file]
      #contournement pour faire le upload apres la creation pour avoir la revision dans
      #get_repository !!!!!!!!!!!!!!
      parameters.delete(:uploaded_file)
      parameters[:volume]=user.volume
      parameters[:owner]=user
      puts "datafile.create_new:param="+parameters.inspect
      datafile=new(parameters)
      #puts "datafile.create_new:save1="+datafile.errors.inspect
      if datafile.save   
        # on sauve le fichier maintenant et le tour est joue
        datafile.create_dir
        if uploaded_file
          datafile.update_attributes(:uploaded_file=>uploaded_file)
          datafile.save
        end
      end
    end
    puts __FILE__+":"+datafile.inspect
    datafile
  end
  
  def update_attributes_repos(params, user)
    parameters=params[:datafile]
    uploaded_file=parameters[:uploaded_file]
    puts "datafile.parameters:param="+parameters.inspect
    parameters[:volume]=user.volume
    if(uploaded_file)
      parameters.delete(:uploaded_file)
      parameters[:revision]=self.revision.next
      self.update_attributes(parameters)
      self.create_dir
      self.update_attributes(:uploaded_file=>uploaded_file)
    else
      self.update_attributes(parameters)
    end
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
    puts "plm_object.get_repository="+self.inspect
    repos=get_dir_repository
    #        begin 
    #          FileUtils.mkdir_p(repos)
    #        rescue Errno::ENOENT
    #          puts "plm_object.get_repository mkdir:"+repos
    #          return nil
    #        end
    if(self.filename!=nil)
      rev=self.revision
      if rev==nil 
        # if @params[:revision]!=nil
        #   rev=@params[:revision]
        # end
        repos=File.join(repos, rev.to_s+"_"+self.filename)
      else
        repos=File.join(repos, self.filename)
      end 
      puts "plm_object.get_repository="+rev.to_s+" filename="+self.filename.to_s
    end
    repos
  end
  
  def read_file
    data = ''
    f = File.open(get_repository, "r") 
    f.each_line do |line|
      data += line
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
  def self.get_conditions(filter)
    filter=filter.gsub("*","%")
    ["ident LIKE ? or "+qry_type+" or revision LIKE ? "+
      " or "+qry_owner_id+" or updated_at LIKE ? or "+qry_volume,
      "#{filter}", 
    "#{filter}", "#{filter}", 
    "#{filter}", "#{filter}", 
    "#{filter}" ] unless filter.nil?
  end
  
end
