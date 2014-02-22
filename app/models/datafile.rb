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
	def dir_repository
		fname= "#{self.class.name}.#{__method__}"
		#LOG.info (fname) {"ident=#{self.ident}"}
		ret= volume.protocol_driver.dir_datafile(self)
		LOG.info (fname) {"ret=#{ret}"}
		ret
	end

	# renvoie les differentes revisions du fichier existantes dans le repository
	def revisions_files
		fname= "#{self.class.name}.#{__method__}"
		#LOG.info (fname) {"datafile=#{self} call #{volume.protocol_driver}.revisions_files"}
		ret= volume.protocol_driver.revisions_files(self)
		ret
	end

	# full path of the file
	def repository
		fname= "#{self.class.name}.#{__method__}"
		#LOG.debug (fname) {"appel #{volume.protocol_driver}.repository"}
		ret= volume.protocol_driver.repository(self)
		ret
	end

	def read_file
		fname= "#{self.class.name}.#{__method__}"
		#LOG.debug (fname) {"appel #{volume.protocol_driver}.read_file"}
		ret= volume.protocol_driver.read_file(self)
		ret
	end

	def create_directory
		fname= "#{self.class.name}.#{__method__}"
		#LOG.debug (fname) {"appel #{volume.protocol_driver}.create_directory volume=#{volume} protocol=#{volume.protocol}"}
		ret = volume.protocol_driver.create_directory(self)
	end

	def write_file(content)
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug (fname) {"content size=#{content.length} volume=#{volume} protocol=#{volume.protocol}"}
		ret=true
		if content.length>0
			create_directory
			repos = self.repository
			#LOG.debug (fname) {"appel #{volume.protocol_driver}.write_file"}
			ret = volume.protocol_driver.write_file(self, content)
		end
		ret
	end

	def delete
		fname= "#{self.class.name}.#{__method__}"
		ret = volume.protocol_driver.remove_files(self)
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

	def self.host=(args)
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug (fname) {"host=#{args.inspect}"}
	##@@host=args.gsub(".","-")
	end

	def self.host
		fname= "#{self.class.name}.#{__method__}"
		#ret=@@host
		ret=PlmServices.get_property("central","sites")
		LOG.debug (fname) {"host_name:#{ret}"}
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
				LOG.debug (fname){"rev=#{revision} next=#{revision.next}"}
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
		LOG.debug (fname){"debut de upload: file_field=#{file_field.inspect}"}
		LOG.debug (fname){"original_filename=#{file_field.original_filename if file_field.respond_to? :original_filename}"}
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
		LOG.debug (fname){"fin de upload:ret=#{ret}"}
		ret
	end

	def base_part_of(file_name)
		fname= "#{self.class.name}.#{__method__}"
		File.basename(file_name).gsub(/[^\w._-]/, '')
	end

	def filename_repository
		fname= "#{self.class.name}.#{__method__}"
		unless self.revision.nil?
			ret = current_revision_file
		else
		ret = self.filename.to_s
		end
		LOG.info (fname) {"filename_repository=#{ret}"}
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
		repos
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

	def remove_files_obsolete
		fname= "#{self.class.name}.#{__method__}"
		if self.volume.protocol == ::Volume::PROTOCOL_FOG
			dir=SylrplmFog.instance.directory(dir_repository)
			unless dir.nil?
				dir.files.each do |file|
					puts "datafile.remove_files:file="+file.inspect
					file.destroy
				end
			dir.destroy
			end
		elsif  self.volume.protocol == ::Volume::PROTOCOL_DATABASE_TEXT || self.volume.protocol == ::Volume::PROTOCOL_DATABASE_BINARY
			ActiveRecord::Base.connection.execute("DELETE FROM #{dir_repository} WHERE datafile = '#{ident}'")
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
