#require 'lib/models/plm_object'
require 'tmpdir'
class Datafile < ActiveRecord::Base
  include Models::PlmObject
  include Models::SylrplmCommon

  attr_accessor :user

  attr_accessor :file_field
  attr_accessor :file_import

  validates_presence_of :ident , :typesobject, :revision, :volume, :owner, :group, :projowner
  validates_uniqueness_of :ident, :scope => :revision

  belongs_to :customer
  belongs_to :document
  belongs_to :part
  belongs_to :project
  
  belongs_to :typesobject
  belongs_to :volume
  belongs_to :owner,
    :class_name => "User"
  belongs_to :group
  belongs_to :projowner,
    :class_name => "Project"

	before_save :upload_file

  FILE_REV_DELIMITER = "--"

	def user=(user)
		fname= "#{self.class.name}.#{__method__}"
		def_user(user)
		self.volume    = user.volume
	end

	def thecustomer=(obj)
		self.customer=obj
	end
	def thedocument=(obj)
		self.document=obj
	end
	def thepart=(obj)
		self.part=obj
	end
	def theproject=(obj)
		self.project=obj
	end
	
  def update_attributes_repos(params, user)
    fname= "#{self.class.name}.#{__method__}"
    LOG.debug (fname){"params=#{params.inspect}"}
    parameters = params[:datafile]
    uploaded_file = parameters[:uploaded_file]
    parameters[:volume]=user.volume
    ret = true
    begin
    	if(uploaded_file)
      ###TODO syl ??? parameters.delete(:uploaded_file)
      parameters[:revision]=self.revision.next
      self.update_attributes(parameters)
      self.create_dir
      self.update_attributes(:uploaded_file => uploaded_file)
    else
      unless params[:restore_file].nil?
        from_rev=Datafile.revision_from_file(params[:restore_file])
        if from_rev!=self.revision.to_s
          if false
            # on remet la revision demandee active en creant une nouvelle revision
            parameters[:revision]=self.revision.next
            parameters[:filename]=Datafile.filename_from_file(params[:restore_file])
            self.update_attributes(parameters)
            move_file(params[:restore_file])
          end
          # on remet la revision demandee active
          parameters[:revision]=from_rev
          parameters[:filename]=Datafile.filename_from_file(params[:restore_file])
        self.update_attributes(parameters)
        else
        self.update_attributes(parameters)
        end
      end
    end
    rescue Exception => e
      	self.errors.add "Error update datafile attributes : #{e}"
      	ret=false
      	e.backtrace.each {|x| LOG.error x}
    end
    ret
  end

  def move_file(from)
    fname= "#{self.class.name}.#{__method__}"
    File.rename(File.join(repository,from), repository)
  end

  def uploaded_file=(file_field)
  	fname= "#{self.class.name}.#{__method__}"
  	LOG.debug (fname){"file_field=#{file_field.inspect}"}
  	self.file_field=file_field
  end
  
  def upload_file
    fname= "#{self.class.name}.#{__method__}"
    #LOG.debug (fname){"filename=#{filename}"}
    LOG.debug (fname){"file_field=#{file_field.inspect}"}
    LOG.debug (fname){"original_filename=#{file_field.original_filename if file_field.respond_to? :original_filename}"}
   	#LOG.debug (fname){"datafile=#{self.inspect}"}
    #if (self.file_field!=nil && self.file_field!="" && self.file_field.original_filename!=nil && self.file_field.original_filename!="")
    unless self.file_field.blank?
      self.content_type = file_field.content_type.chomp if file_field.respond_to? :content_type
      self.filename = base_part_of(file_field.original_filename) if file_field.respond_to? :original_filename
      #LOG.debug (fname){"filename=#{self.filename} content_type=#{self.content_type}"}
      content = file_field.read
      begin
      write_file(content)
      self.file_field=nil
      rescue Exception => e
      	raise Exception.new "Error uploaded file #{file_field}:#{e}"
      end
    else unless self.file_import.nil?
      self.filename = base_part_of(file_import[:original_filename])
      content =  file_import[:file].read
      begin
      write_file(content)
      self.file_field=nil
      rescue Exception => e
      	raise Exception.new "Error uploaded file #{file_field}:#{e}"
      	e.backtrace.each {|x| LOG.error x}
      end
    	end
    end
    
  end

  def base_part_of(file_name)
    fname= "#{self.class.name}.#{__method__}"
    File.basename(file_name).gsub(/[^\w._-]/, '')
  end

  def dir_repository
    fname= "#{self.class.name}.#{__method__}"
    LOG.info (fname) {"ident=#{self.ident}"}
    ret=""
    if self.volume.protocol == "fog"
      ret=self.volume.dir_name.gsub("/",".").gsub("_",".")+"."+self.class.name+"."+self.ident
      if ret.start_with?(".")
      ret=ret[1,ret.length-1]
      end
      ret=ret.downcase
    else
      unless self.volume.dir_name.nil? || self.ident.nil?
        ret=File.join self.volume.dir_name.gsub("_","-"), self.class.name, self.ident
      end
    end
    ret
  end
  
  def repository
    fname= "#{self.class.name}.#{__method__}"
    # on prend le volume du fichier lui meme
    #puts "datafile.repository:#{self.inspect}"
    unless self.filename.nil?
      if self.volume.protocol == "fog"
        ret = "#{dir_repository}.#{filename_repository}"
      else
        ret = File.join(dir_repository, filename_repository)
      end
    end
    ret
  end

  def filename_repository
    fname= "#{self.class.name}.#{__method__}"
    unless self.revision.nil?
      ret = FILE_REV_DELIMITER+self.revision.to_s+FILE_REV_DELIMITER+self.filename.to_s
    else
    ret = self.filename.to_s
    end 
    LOG.info (fname) {"filename_repository=#{ret}"}
    ret
  end

  # renvoie les differentes revisions du fichier existantes dans le repository
  def revisions_files
    fname= "#{self.class.name}.#{__method__}"
    ret=[]
    if self.volume.protocol == "fog"
      dir=SylrplmFog.instance.directory(dir_repository)
      dir.files.each do |file|
        ret<<file.key.to_s
      end unless dir.nil?
    else
      dir=self.dir_repository
      if File.exists?(dir)
        repos=filename_repository
        Dir.foreach(dir) { |file|
          filename=file.split(FILE_REV_DELIMITER)[2]
          revision=file.split(FILE_REV_DELIMITER)[1]
          unless filename.nil? && revision.nil?
          #puts "plm_object.get_revisions;file="+file+" name="+filename.to_s+" rev="+revision.to_s
          ret<<file.to_s
          end
        }
      end
    end
    #puts "plm_object.get_revisions:"+ret.length.to_s
    ret
  end

  def self.revision_from_file(_filename)
    fname= "#{self.class.name}.#{__method__}"
    _filename.split(FILE_REV_DELIMITER)[1]
  end

  def self.filename_from_file(_filename)
    fname= "#{self.class.name}.#{__method__}"
    _filename.split(FILE_REV_DELIMITER)[2]
  end

  def current_revision_file
  	fname= "#{self.class.name}.#{__method__}"
    #puts "current_revision_file:"+self.revision.to_s+" filename="+self.filename.to_s
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
    fname= "#{self.class.name}.#{__method__}"
    if File.exists?(repository)
      data=''
      f = File.open(repository, "r")
      f.each_line do |line|
        data += line
        #puts "datafile.read_file a line"
      end
    else
      data=nil
    end
    data
  end

  def read_file
  	fname= "#{self.class.name}.#{__method__}"
    if self.volume.protocol == "fog"
      fog_file=SylrplmFog.instance.retrieve(self.dir_repository, self.filename_repository)
      data=nil
    data=fog_file.body unless fog_file.nil?
    else
      if File.exists?(repository)
        data=''
        f = File.open(repository, "rb")
        nctot = File.size(repository)
        LOG.debug (fname) {"debut lecture #{repository}: #{nctot}"}
        data = f.sysread(nctot)
        f.close
        LOG.debug (fname) {"fin lecture #{repository}"}
      else
        data=nil
      end
    end
    data
  end
  
	def read_file_old
  	fname= "#{self.class.name}.#{__method__}"
    if self.volume.protocol == "fog"
      fog_file=SylrplmFog.instance.retrieve(self.dir_repository, self.filename_repository)
      data=nil
    data=fog_file.body unless fog_file.nil?
    else
      if File.exists?(repository)
        data=''
        f = File.open(repository, "rb")
        nctot = File.size(repository)
        LOG.debug (fname) {"debut lecture #{repository}: #{nctot}"}
        nc=0
        f.each_byte do |ch|
          data += ch.chr
          nc+=1
          ###puts " "+ch.to_s+":"+nc.to_s+":"+nctot.to_s
          if nc >= nctot 
          	break
          end
        #puts " "+nc.to_s
        end
        f.close
        LOG.debug (fname) {"fin lecture #{repository}"}
      else
        data=nil
      end
    end
    data
  end

  def create_dir
    fname= "#{self.class.name}.#{__method__}"
    if self.volume.protocol == "fog"
      dir = SylrplmFog.instance.create_directory(dir_repository)
    else
      FileUtils.mkdir_p(dir_repository) unless File.exists?(dir_repository)
    end
  end

  def write_file(content)
    fname= "#{self.class.name}.#{__method__}"
    create_dir
    repos = self.repository
    LOG.info (fname) {"repository=#{repos}, content size=#{content.length}"}
    if content.length>0
	    if self.volume.protocol == "fog"
	      fog_file = SylrplmFog.instance.upload_content(dir_repository, self.filename_repository, content)
	      LOG.info (fname) {"write_file in fog:#{fog_file.inspect}"}
	    else
	      f = File.open(repos, "wb")
	      begin
	    		f.puts(content)
	    	rescue Exception => e
	    		e.backtrace.each {|x| LOG.error x}
	    		raise Exception.new "Error writing in server file #{repos}:#{e}"
	    		
	    	end
	    	f.close
	    end
    end
  end
  
  #
  # ecriture dans un fichier temporaire dans public/tmp pour visu ou edition par un outil externe
  #
  def write_file_tmp
    fname= "#{self.class.name}.#{__method__}"
    content = read_file
    repos=nil
    if content.length>0
    	dir_repos=File.join("public")
    	tmpfile=File.join("tmp", filename_repository)
    	FileUtils.mkdir_p(dir_repos) unless File.exists?(dir_repos)
    		repos = File.join(dir_repos, tmpfile)
    		LOG.info (fname) {"repository=#{repos}"}
	      unless File.exists?(repos)
		      f = File.open(repos, "wb")
		      begin
		    		f.puts(content)
		    	rescue Exception => e
		    		e.backtrace.each {|x| LOG.error x}
		    		raise Exception.new "Error writing in tmp file #{repos}:#{e}"	
		    	end
		    	f.close
	    	end
	 	end
	 	tmpfile 
  end

  def file_exists?
    fname= "#{self.class.name}.#{__method__}"
    File.exists?(repository)
  end

  def remove_file
    fname= "#{self.class.name}.#{__method__}"
    repos=repository
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
    fname= "#{self.class.name}.#{__method__}"
    self.remove_files
    self.destroy
  end

  def find_col_for(strcol)
    fname= "#{self.class.name}.#{__method__}"
    Sequence.find_col_for(self.model_name,strcol)
  end

  def self.get_conditions(filter)
    fname= "#{self.class.name}.#{__method__}"
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
  
  def remove_files
    fname= "#{self.class.name}.#{__method__}"
    if self.volume.protocol == "fog"
      dir=SylrplmFog.instance.directory(dir_repository)
      unless dir.nil?
        dir.files.each do |file|
          puts "datafile.remove_files:file="+file.inspect
          file.destroy
        end
      dir.destroy
      end
    else
      dir = dir_repository
      #puts "datafile.remove_files:"+dir
      if File.exists?(dir)
        Dir.foreach(dir) { |file|
          repos=File.join(dir,file)
          puts "datafile.remove_files:file="+repos
          if File.file?(repos)
            File.unlink(repos)
          end
        }
        Dir.rmdir(dir)
      end

    end
  end
end
