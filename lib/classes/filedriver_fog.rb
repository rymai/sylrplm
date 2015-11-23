# acces au serveur de fichier fog sur le cloud
require 'fog'
require 'classes/filedriver'

class FiledriverFog < Filedriver

	private
	def initialize
		puts "SylrplmFog.initialize"
	end

	public

	#attributs d'instance
	attr_accessor :storage

	# une seule instance car une seule connection au server fog
	@@instance = nil

	def self.instance
		fname= "FiledriverFog.#{__method__}"
		access_key=::SYLRPLM::FOG_ACCESS_KEY
		access_key_id=::SYLRPLM::FOG_ACCESS_KEY_ID
		if @@instance.nil?
			LOG.info (fname) {"access_key=#{access_key} access_key_id=#{access_key_id}"}
			@@instance = FiledriverFog.new
			# create a connection
			@@instance.storage = Fog::Storage.new(
			{
				:provider                 => 'AWS',
				:aws_secret_access_key    => access_key,
				:aws_access_key_id        => access_key_id,
				# authorize the period (.) in the hostname
				:path_style => true
			})
		end
		LOG.debug (fname) {"@@instance=#{@@instance.inspect}"}
		return @@instance
	end

	########################################################################
	# protocol calls begin
	########################################################################
	def dir_datafile(datafile)
		fname= "FiledriverFog.#{__method__}"
		#LOG.info (fname) {"ident=#{datafile.ident}"}
		vol_dir=datafile.volume.dir_name.gsub("_","-")
		vol_dir=vol_dir.gsub("/",::Volume::DIR_DELIMITER)
		ret="#{vol_dir}#{::Volume::DIR_DELIMITER}#{datafile.class.name}#{::Volume::DIR_DELIMITER}#{datafile.ident}"
		if ret.start_with?(".") || ret.start_with?("-")
		ret=ret[1,ret.length-1]
		end
		ret=ret.downcase
		ret
	end

	# renvoie les differentes revisions du fichier existantes dans le repository
	def revisions_files(datafile)
		fname= "FiledriverFog.#{__method__}"
		ret=[]
		dir=directory(datafile.dir_repository)
		unless dir.nil?
			dir.files.each do |file|
				ret<<file.key.to_s
			end
		end
		ret
	end

	# full path of the file
	def repository(datafile)
		fname= "FiledriverFog.#{__method__}"
		ret=""
		unless datafile.filename.nil?
			ret = "#{datafile.dir_repository}.#{datafile.filename_repository}"
		end
		ret
	end

	def read_file(datafile)
		fname= "FiledriverFog.#{__method__}"
		fog_file = retrieve(datafile.dir_repository, datafile.filename_repository)
		data=fog_file.body unless fog_file.nil?
		#LOG.debug (fname) {"fog_file=#{fog_file} taille=#{data}"}
		data
	end

	#
	# renvoie un repertoire dans lequel seront uploade les fichiers
	def create_directory(datafile)
		fname= "FiledriverFog.#{__method__}"
		#LOG.debug (fname) {"datafile.dir_repository=#{datafile.dir_repository}"}
		directory_key=datafile.dir_repository
		#dir = create_directory(datafile.dir_repository)
		unless directory_exists?(directory_key)
			directory = storage.directories.create(
			{
				#      :key    => "fog-sylrplm-#{Time.now.to_i}", # globally unique name
				:key    => directory_key, # globally unique name
				:public => true
			})
		directory
		else
		directory_key
		end
	end

	def write_file(datafile, content)
		fname= "FiledriverFog.#{__method__}"
		LOG.debug (fname) {"content size=#{content.length}"}
		if content.length>0
			fog_file = upload_content(datafile.dir_repository, datafile.filename_repository, content)
			LOG.debug (fname) {"apres write in fog:#{fog_file.inspect}"}
		end
	end

	#
	# creation ou deplacement du repertoire du volume
	# - file_systeme: creation sur le disque du serveur suivant le chemin complet
	# - fog:
	# - database: creation de la table de nom=name
	def create_volume_dir(volume, olddirname)
		fname= "FiledriverFog.#{__method__}"
		ret = volume.directory
		if volume.dir_name != olddirname
			ret=nil
			volume.errors.add_to_base "The directory of fog volume can't be moved"
		end
		LOG.debug (fname) {"ret=#{ret}"}
		return ret
	end

	def delete_volume_dir(volume)
		true
	end

	def remove_files(datafile)
		fname= "FiledriverFog.#{__method__}"
		dir=directory(datafile.dir_repository)
		unless dir.nil?
			dir.files.each do |file|
				puts "datafile.remove_files:file="+file.inspect
				file.destroy
			end
		dir.destroy
		end
	end

	def files_list(purge = false)
		fname= "FiledriverFog.#{__method__}"
		# list directories
		#LOG.debug (fname){"purge=#{purge} storage=#{self.storage.inspect}"}
		ret=[]
		files_fog=[]
		begin
			ret = self.storage.directories
			ret.each do |ddd|
			#LOG.debug (fname){"directorie=#{ddd.inspect}"}
				ddd.files.each do |s3_file|
					if(purge==true )
						is_used = is_used?(ddd, s3_file)
						#LOG.debug (fname){"\tfile:#{s3_file.inspect} is_used?=#{is_used}"}
						if(!is_used)
						s3_file.destroy
						end
					end
				end
				if(purge==true)
					#LOG.debug (fname){"ddd.files.count=#{ddd.files.count}"}
					if(ddd.files.count==0)
						LOG.info (fname){"destroy de #{ddd.inspect}"}
					ddd.destroy
					end
				end
			end
			begin
				ret.each do |s3_dir|
					s3_dir.files.each do |s3_file|
					#LOG.debug (fname) {"dir=#{s3_dir.inspect} s3_file=#{s3_file.inspect}"}
					# 0-0-0-0.deve.volfog01.datafile.df0000000057
						fields_dir = s3_dir.key.split(::Volume::DIR_DELIMITER)
						params = {}
						# abort.png
						params["filename"]=::Datafile.filename_from_file(s3_file.key)
						# 1
						params["revision"]=::Datafile.revision_from_file(s3_file.key)
						#
						if(fields_dir.size==5)
							params["datafile_model"] = fields_dir[3]
							params["datafile"] =  fields_dir[4]
							params["volume_dir"] = fields_dir[0] + ::Volume::DIR_DELIMITER + fields_dir[1] + ::Volume::DIR_DELIMITER + fields_dir[2]
						end
						params["protocol"]=self.protocol
						params["size"]=s3_file.content_length
						params["domain"]=""
						params["updated_at"]=s3_file.last_modified
						params["id"]=buildFileId(s3_dir.key, s3_file.key)
						#LOG.debug (fname) {"id=#{params["id"]}"}
						sylrplmfile=SylrplmFile.new(params)
						files_fog<<sylrplmfile
					end
				end
			rescue Exception=>e
				cmd="Exception during files_list:#{e.message}"
				#LOG.error (fname){cmd}
				### TODO: la mettre sur la base sans objet particulier volume.errors.add_to_base(cmd)
				e.backtrace.each {|x| LOG.error x}
			end
		rescue Exception=>e
			LOG.error (fname){"fog access error:#{e}"}
		end
		files_fog
	end

	# <Fog::Storage::AWS::Directory
	#   key="0-0-0-0.deve.volfog01.datafile.df0000000057",
	#   creation_date=2014-01-02 20:10:11 UTC
	#
	# <Fog::Storage::AWS::File
	#   key="_._1_._abort.png",
	#       cache_control=nil,
	#       content_disposition=nil,
	#       content_encoding=nil,
	#       content_length=373,
	#       content_md5=nil,
	#       content_type=nil,
	#       etag="77ea56740624ceba2ccba6d4b44aa14a",
	#       expires=nil,
	#       last_modified=2014-01-02 20:10:12 UTC,
	#      metadata={},
	#       owner={:display_name=>nil, :id=>nil},
	#       storage_class="STANDARD"

	def delete_file(id)
		fid = splitId(id)
		remove_file(fid[:s3dirkey], fid[:s3filekey])
	end

	########################################################################
	# protocol calls end
	########################################################################
	def splitId(id)
		id=super(id)
		fields = id.split(::SylrplmFile::FILE_SEP_ID)
		ret={:protocol => fields[0], :s3dirkey => fields[1], :s3filekey => fields[2]}
	end

	def buildFileId(s3dirkey, s3filekey)
		super("#{protocol}#{::SylrplmFile::FILE_SEP_ID}#{s3dirkey}#{::SylrplmFile::FILE_SEP_ID}#{s3filekey}")
	end

	def directory_exists?(adir)
		fname= "FiledriverFog.#{__method__}"
		#LOG.debug (fname){"adir=#{adir}"}
		dirs = FiledriverFog.instance.storage.directories
		ret=false
		#dirs.include? adir
		dirs.each do |dir|
			if dir.key==adir
			ret=true
			break
			end
		end
		ret
	end

	def is_used?(direct, s3_file)
		fname= "FiledriverFog.#{__method__}"
		#key_dir=0-0-0-0.deve.volfog01.datafile.df0000000038
		fields_dir=direct.key.split(::Volume::DIR_DELIMITER)
		if fields_dir.size==5
			host=fields_dir[0]
			envir=fields_dir[1]
			volume_name=fields_dir[2]
			datafile_model=fields_dir[3].capitalize
			datafile_ident=fields_dir[4].upcase!
			#LOG.debug (fname){"#{(fields_dir.count==5 ? "OK(5)" : "KO(#{fields_dir.count})")} direct.key=#{direct.key} volume_name=#{volume_name} datafile_model=#{datafile_model} datafile_ident=#{datafile_ident}"}
			#key_file:--1--pied_rond_long.odt
			fields_file=s3_file.key.split(::Volume::FILE_REV_DELIMITER)
			file_rev=fields_file[1]
			file_name=fields_file[2]
			#LOG.debug (fname){"#{(fields_file.count==3 ? "OK(3)" : "KO(#{fields_file.count})")} s3_file.key=#{s3_file.key} file_rev=#{file_rev} file_name=#{file_name}"}
			#
			if(fields_dir.count==5 && fields_file.count==3)
				datafiles = (eval datafile_model).find_by_ident_and_revision_and_filename(datafile_ident, file_rev, file_name)
			ret = !datafiles.nil?
			else
			ret=false
			end
		else
		ret=false
		end
		#LOG.debug (fname){"ret=#{ret}"}
		ret
	end

	def directory(directory_key)
		fname= "#{self.class.name}.#{__method__}"
		begin
			ret=storage.directories.get(directory_key)
			#puts "sylrplm_fog.directory("+directory_key+")="+ret.inspect
		rescue Exception => exc
			LOG.debug (fname){"Exception during fog access, verify the network, dir_key=#{directory_key} exception=#{exc}"}
			ret=nil
		end
		ret
	end

	def file(directory_key, file_key)
		#puts "sylrplm_fog.file("+directory_key+","+ file_key+")"
		dir=directory(directory_key)
		ret=dir.files.get(file_key) unless dir.nil?
		#puts "sylrplm_fog.file("+directory_key+","+ file_key+")="+ret.inspect
		ret
	end

	# upload d'un fichier
	def upload_file(directory_key, file_key, local_filename)
		# upload
		fog_file = directory(directory_key).files.create({
			:key    => file_key,
			:body   => File.open(local_filename),
			:public => true
		})
		fog_file
	end

	# upload d'un contenu
	def upload_content(directory_key, file_key, content)
		fname= "FiledriverFog.#{__method__}"
		LOG.debug (fname) {"directory_key=#{directory_key}  file_key= #{file_key}"}
		# upload
		fog_file = directory(directory_key).files.create({
			:key    => file_key,
			:body   => content,
			:public => true
		})
		fog_file
	end

	def update(directory_key, file_key, local_filename)
		fog_file = file(directory_key, file_key)
		update_file(fog_file, local_filename)
	end

	def retrieve(directory_key, file_key)
		#puts "sylrplm_fog.retrieve("+directory_key+","+ file_key+")"
		# get the resume file
		fog_file = file(directory_key, file_key)
	end

	def backup(directory)
		# copy each file to local disk
		nb=0
		directory.files.each do |s3_file|
			File.open(s3_file.key, 'w') do |local_file|
				local_file.write(s3_file.body)
				nb+=1
			end
		end
		nb
	end

	def update_file(fog_file, local_filename)
		fog_file.body = File.open(local_filename)
		fog_file.save
		fog_file
	end

	def self.remove_repository(dirkey)
		fname= "FiledriverFog.#{__method__}"
		LOG.info (fname) {"deleting dir:#{dirkey}"}
		dir = SylrplmFog.instance.directory(dirkey)
		unless dir.nil?
			dir.files.each do |file|
				LOG.info (fname) {"deleting fog file:#{file.inspect}"}
				file.destroy
			end
		dir.destroy
		end
	end

	def remove_file(dirkey, filekey)
		fname= "FiledriverFog.#{__method__}"
		LOG.info (fname) {"deleting dir:#{dirkey},#{filekey}"}
		dir = FiledriverFog.instance.directory(dirkey)
		unless dir.nil?
			dir.files.each do |file|
				LOG.info (fname) {"deleting fog file:#{file.inspect}"}
				file.destroy if file.key==filekey
			end
			LOG.info (fname) {"dir=#{dir.inspect}"}
		dir.destroy if dir.files.size==0
		end
	end

	def protocol
		"fog"
	end

end