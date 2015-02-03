require 'tmpdir'
require "zip/zip"

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
	# for rules about fog names
	# http://docs.aws.amazon.com/AmazonS3/latest/dev/BucketRestrictions.html
	#
	# pg sql examples
	#DELETE FROM `comments` WHERE `comments`.`post_id` = 11
	#INSERT INTO comments (author, content, email, post_id) VALUES (?, ?, ?, ?);
	#SELECT * FROM posts;
	#SELECT tags.* FROM tags
	# INNER JOIN posts_tags ON tags.id = posts_tags.tag_id
	# WHERE posts_tags.post_id IS ?;
	#SELECT * FROM posts WHERE author IN ('Nicolas', 'Toto') OR title LIKE 'Titre%';
	#ActiveRecord::Base.connection.select_one('SELECT COUNT(*) FROM mytable')
	#ActiveRecord::Base.connection.execute('SELECT * FROM mytable')
	#
	########################################################################
	# protocol calls begin
	########################################################################
	#
	def designation; ident; end

	def dir_repository
		fname= "#{self.class.name}.#{__method__}"
		#LOG.info (fname) {"ident=#{self.ident}"}
		ret= volume.protocol_driver.dir_datafile(self)
		#LOG.info (fname) {"ret=#{ret}"}
		ret
	end

	# renvoie les differentes revisions du fichier existantes dans le repository
	def revisions_files
		fname= "#{self.class.name}.#{__method__}"
		#LOG.info (fname) {"datafile=#{self} call #{volume.protocol_driver}.revisions_files"}
		ret= volume.protocol_driver.revisions_files(self)
		ret
	end

	#
	# full path of the file
	#
	def repository
		fname= "#{self.class.name}.#{__method__}"
		#LOG.debug (fname) {"appel #{volume.protocol_driver}.repository"}
		ret= volume.protocol_driver.repository(self)
		ret
	end

	def read_file
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug (fname) {"appel #{volume.protocol_driver}.read_file"}
		ret= volume.protocol_driver.read_file(self)
		ret
	end

	# read the file and adapt it for include the content in a tree model file
	def read_file_for_tree
		fname= "#{self.class.name}.#{__method__}"
		#LOG.debug (fname) {"content=#{read_file}"}
		code_content=self.typesobject.get_fields_values_type_only_by_key("build_tree_file_content")
		unless code_content.nil?
			bloc=""
			bloc << "		content = self.read_file\n"
			bloc << "		unless content.nil?\n"
			bloc << "		  ##puts \">>read_file_for_tree:\#{self.file_fullname} : \#{content.size}\n\#{content}\"\n"
			bloc << "		  #{code_content}\n"
			bloc << "		  ##puts \">>read_file_for_tree:ret=\n\#{ret}\"\n"
			bloc << "		else\n"
			bloc << "			ret=\"\"\n"
			bloc << "		end\n"
			bloc << "		ret"
			#LOG.debug (fname) {"****************** bloc=\n#{bloc}\n**********"}
			ret = eval bloc
		else
		# no code to modify the file, we read the file as is
		ret = self.read_file
		end
		#LOG.debug (fname) {"****************** ret=\n#{ret}"}
		ret
	end

	#
	# read the file and adapt it for using the file outside the application
	#
	def read_file_for_download
		fname= "#{self.class.name}.#{__method__}"
		code_content=self.typesobject.get_fields_values_type_only_by_key("build_file_content")
		unless code_content.nil?
			bloc=""
			bloc << "		content = self.read_file\n"
			bloc << "		unless content.nil?\n"
			bloc << "		  ##puts \">>read_file_for_download:\#{self.file_fullname} : \#{content.size}\"\n"
			bloc << "		  #{code_content}\n"
			bloc << "		  else\n"
			bloc << "			return nil\n"
			bloc << "		end\n"
			bloc << "		ret\n"
			LOG.debug (fname) {"****************** bloc=\n#{bloc}\n**********"}
			ret = eval bloc
		else
			LOG.debug (fname) {"pas de bloc => read_file"}
		# no code to modify the file, we read the file as is
		ret = self.read_file
		end
		LOG.debug (fname) {"****************** ret=\n#{ret}"}
		ret
	end

	def create_directory
		fname= "#{self.class.name}.#{__method__}"
		#LOG.debug (fname) {"appel #{volume.protocol_driver}.create_directory volume=#{volume} protocol=#{volume.protocol}"}
		ret = volume.protocol_driver.create_directory(self)
	end

	def write_file(content)
		fname= "#{self.class.name}.#{__method__}"
		#LOG.debug (fname) {"content size=#{content.length} volume=#{volume} protocol=#{volume.protocol}"}
		ret=true
		if content.length>0
			create_directory
			repos = self.repository
			#LOG.debug (fname) {"appel #{volume.protocol_driver}.write_file"}
			ret = volume.protocol_driver.write_file(self, content)
		end
		ret
	end

	def m_destroy
		fname= "#{self.class.name}.#{__method__}"
		ret = volume.protocol_driver.remove_files(self)
		unless self.customer.nil?
			customer.remove_datafile(self)
		end
		unless self.document.nil?
			document.remove_datafile(self)
		end
		unless self.part.nil?
			part.remove_datafile(self)
		end
		unless self.project.nil?
			project.remove_datafile(self)
		end
		self.destroy
	end

	#TODO: dispatcher dans les drivers
	def move_file(from)
		fname= "#{self.class.name}.#{__method__}"
		File.rename(File.join(repository,from), repository)
	end

	#TODO: dispatcher dans les drivers
	def file_exists?
		fname= "#{self.class.name}.#{__method__}"
		File.exists?(repository)
	end

	#TODO: dispatcher dans les drivers
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

	########################################################################
	# protocol calls end
	########################################################################

	def self.m_create(params)
		fname= "#{self.class.name}.#{__method__}"
		uploadedfile = params.delete(:uploaded_file)
		datafile = Datafile.new(params[:datafile])
		st=datafile.save
		LOG.debug (fname){"datafile save : st=#{st}"}
		if st
			st=datafile.create_directory
			LOG.debug (fname){"datafile .create_directory : st=#{st}"}
			if uploadedfile
				st=datafile.update_attributes(:uploaded_file => uploadedfile)
				LOG.debug (fname){"uploadedfile : st=#{st}"}
			end
		end
		LOG.debug (fname){"datafile errors =#{datafile.errors.full_messages}"}
		datafile
	end

	def m_update(params, user)
		update_accessor(user)
		stupd = update_attributes_repos(params, user)
	end

	def self.host=(args)
		fname= "#{self.class.name}.#{__method__}"
	#LOG.debug (fname) {"host=#{args.inspect}"}
	##@@host=args.gsub(".","-")
	end

	def self.host
		fname= "#{self.class.name}.#{__method__}"
		#ret=@@host
		ret=PlmServices.get_property("central","sites")
		#LOG.debug (fname) {"host_name:#{ret}"}
		ret
	end

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
		#LOG.debug (fname){"params=#{params.inspect}"}
		parameters = params[:datafile]
		uploaded_file = parameters[:uploaded_file]
		parameters[:volume]=user.volume unless parameters[:volume].nil?
		ret = true
		begin
			LOG.debug (fname){"params[volume_id]=#{params["volume_id"]} uploaded_file=#{uploaded_file}"}
			if(uploaded_file)
				###TODO syl ??? parameters.delete(:uploaded_file)
				#LOG.debug (fname){"rev=#{revision} next=#{revision.next}"}
				parameters[:revision]=self.revision.next
				self.update_attributes(parameters)
				self.create_directory
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

	def volumes
		owner.group.volumes unless owner.nil?
	end

	def uploaded_file=(file_field)
		fname= "#{self.class.name}.#{__method__}"
		#LOG.debug (fname){"file_field=#{file_field.inspect} volume=#{volume} protocol=#{volume.protocol}"}
		self.file_field = file_field
	end

	def upload_file
		fname= "#{self.class.name}.#{__method__}"
		#LOG.debug (fname){"filename=#{filename}"}
		#LOG.debug (fname){"debut de upload: file_field=#{file_field.inspect}"}
		#LOG.debug (fname){"original_filename=#{file_field.original_filename if file_field.respond_to? :original_filename}"}
		#LOG.debug (fname){"datafile=#{self.inspect}"}
		unless self.file_field.blank?
			self.content_type = file_field.content_type.chomp if file_field.respond_to? :content_type
			self.filename = base_part_of(file_field.original_filename) if file_field.respond_to? :original_filename
			#LOG.debug (fname){"filename=#{self.filename} content_type=#{self.content_type}"}
			#content = file_field.read
			content = open(file_field.path,"rb") { |io| io.read }
			ret = write_file(content)
			self.file_field=nil
		else unless self.file_import.nil?
				self.filename = base_part_of(file_import[:original_filename])
				content =  file_import[:file].read
				begin
					ret = write_file(content)
					self.file_field=nil
				rescue Exception => e
					LOG.error (fname){"Exception 2 during write_file: #{e.inspect} "}
					e.backtrace.each {|x| LOG.error x}
					if e.class==Excon::Errors::SocketError
						LOG.error (fname){"Probleme potentiel de connection reseau:#{e.class}:#{e.message}"}
					end
					ret=false
					raise Exception.new "Error uploaded file 2 #{file_field}:#{e}"
				end
			end
		end
		#LOG.debug (fname){"fin de upload:ret=#{ret}"}
		ret
	end

	def base_part_of(file_name)
		fname= "#{self.class.name}.#{__method__}"
		File.basename(file_name).gsub(/[^\w._-]/, '')
	end

	def file_path
		File.basename(self.filename)
	end

	# return the filename without the dir path and the extension
	def file_name
		File.basename(self.filename).split(".")[0]
	end

	def file_fullname
		ret=file_name
		ext=file_extension
		ret+=".#{ext}" unless ext.blank?
		ret
	end

	# return the extension of the file, nil if no . in the name
	def file_extension
		sp=File.basename(filename).split(".")
		sp[sp.size-1] if sp.size>1
	end

	def filename_repository
		fname= "#{self.class.name}.#{__method__}"
		unless self.revision.nil?
			ret = current_revision_file
		else
		ret = self.filename.to_s
		end
		#LOG.info (fname) {"filename_repository=#{ret}"}
		ret
	end

	def self.revision_from_file(_filename)
		fname= "#{self.class.name}.#{__method__}"
		#LOG.info (fname) {"_filename=#{_filename}"}
		_filename.split(Volume::FILE_REV_DELIMITER)[1]
	end

	def self.filename_from_file(_filename)
		fname= "#{self.class.name}.#{__method__}"
		#LOG.info (fname) {"_filename=#{_filename}"}
		_filename.split(Volume::FILE_REV_DELIMITER)[2]
	end

	def current_revision_file
		fname= "#{self.class.name}.#{__method__}"
		#puts "current_revision_file:"+self.revision.to_s+" filename="+self.filename.to_s
		ret=""
		unless self.revision.blank? && self.filename.blank?
			ret=Volume::FILE_REV_DELIMITER
			ret+=self.revision.to_s
			ret+=Volume::FILE_REV_DELIMITER
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

	#
	# ecriture dans un fichier temporaire dans public/tmp pour visu ou edition par un outil externe
	#
	def write_file_tmp
		fname= "#{self.class.name}.#{__method__}"
		content = read_file_for_download
		repos=nil
		LOG.debug (fname) {"content.length=#{content.length}"}
		if content.length>0
			dir_repos=File.join("public","tmp")
			FileUtils.mkdir_p(dir_repos) unless File.exists?(dir_repos)
			tmpfilename=repository.gsub("/","_")
			repos = File.join(dir_repos, tmpfilename)
			LOG.debug (fname) {"repository=#{repos} dir_repos=#{dir_repos} exist=#{File.exists?(dir_repos)}"}
			unless File.exists?(repos)
				if File.exists?(dir_repos)
					f = File.open(repos, "wb")
					begin
						f.puts(content)
						LOG.debug (fname) {"file is writed in #{repos}:#{File.exists?(repos)}"}
					rescue Exception => e
						e.backtrace.each {|x| LOG.error x}
						raise Exception.new "Error writing in tmp file #{repos}:#{e}"
					end
				f.close
				else
					LOG.error (fname) {"#{dir_repos} does not exist and can t be created"}
				end
			else
				LOG.debug (fname) {"#{repos} already existing, using it"}
			end
		end
		ret = File.join("/tmp",tmpfilename)
		LOG.info (fname) {"src=#{ret} exist=#{File.exists?(repos)}"}
		ret
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
			ret[:qry] = "ident LIKE :v_filter or revision LIKE :v_filter or to_char(updated_at, 'YYYY/MM/DD')  LIKE :v_filter or "+qry_owner_id+" or "+qry_type+" or "+qry_volume
			ret[:values]={:v_filter => filter}
		end
		ret

	#["ident LIKE ? or "+qry_type+" or revision LIKE ? "+
	#  " or "+qry_owner_id+" or updated_at LIKE ? or "+qry_volume,
	end

	def zipFile
		fname= "#{self.class.name}.#{__method__}"
		#LOG.debug (fname) {"datafile=#{self}"}
		tmpname="datafile.#{self.id}.#{self.filename.gsub("/","-").gsub("\\","-")}"
		tmpfile = Tempfile.new("#{tmpname}-#{Time.now}")
		LOG.debug (fname) {"tmpname=#{tmpname}"}
		content=self.read_file_for_download
		unless content.blank?
			size=content.size
			Zip::ZipOutputStream.open(tmpfile) do |zio|
				zio.put_next_entry(tmpname)
				zio.write content
			end
		else
		size=0
		end
		ret={:size=>size, :file=>tmpfile, :filename=>"#{@filename}.zip", :content_type=>"application/zip"}
		#LOG.debug (fname) {"ret=#{ret.inspect}"}
		ret
	end
end
