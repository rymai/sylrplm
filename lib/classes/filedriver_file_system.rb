require 'classes/filedriver'
require 'zip'
class FiledriverFileSystem < Filedriver

	private
	def initialize
		puts "FiledriverFileSystem.initialize"
	end

	public

	#attributs d'instance
	attr_accessor :storage

	# une seule instance car une seule connection au server fog
	@@instance = nil

	def self.instance
		if @@instance.nil?
			@@instance = FiledriverFileSystem.new
		end
		#puts "SylrplmFog.instance:"+@@instance.inspect
		return @@instance
	end

	########################################################################
	# protocol calls begin
	########################################################################
	def dir_datafile(datafile)
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug(fname) {"datafile.volume.dir_name=#{datafile.volume.dir_name} datafile.class.name=#{datafile.class.name} ident=#{datafile.ident}"}
		ret=""
		unless datafile.volume.dir_name.nil? || datafile.ident.nil?
			ret=File.join datafile.volume.dir_name.gsub("_","-"), datafile.modelname, datafile.ident
		end
		LOG.debug(fname) {"dir_datafile=#{ret}"}
		ret
	end

	# renvoie les differentes revisions du fichier existantes dans le repository
	def revisions_files(datafile)
		fname= "#{self.class.name}.#{__method__}"
		ret=[]
		dir = datafile.dir_repository
		if File.exists?(dir)
			repos=datafile.filename_repository
			Dir.foreach(dir) do |file|
				filename=::Datafile.filename_from_file(file)
				revision=::Datafile.revision_from_file(file)
				unless filename.nil? && revision.nil?
				#puts "plm_object.get_revisions;file="+file+" name="+filename.to_s+" rev="+revision.to_s
				ret<<file.to_s
				end
			end
		end
		ret
	end

	# full path of the file
	def repository(datafile)
		fname= "#{self.class.name}.#{__method__}"
		ret=""
		unless datafile.filename.nil?
			ret = File.join(datafile.dir_repository, datafile.filename_repository)
		end
		ret
	end

	def read_file(datafile)
		fname= "#{self.class.name}.#{__method__}"
		if File.exists?(datafile.repository)
			data=''
			f = File.open(datafile.repository, "rb")
			nctot = File.size(datafile.repository)
			data = f.sysread(nctot)
			f.close
			LOG.debug(fname) {"fin lecture #{datafile.repository}: #{nctot}"}
		else
			data=nil
		end
		data
	end

	# renvoie un repertoire dans lequel seront uploade les fichiers
	def create_directory(datafile)
		fname= "#{self.class.name}.#{__method__}"
		#LOG.debug(fname) {"dir_repository=#{datafile.dir_repository}"}
		FileUtils.mkdir_p(datafile.dir_repository) unless directory_exists?(datafile.dir_repository)
	end

	def write_file(datafile, content)
		fname= "#{self.class.name}.#{__method__}"
		repos=datafile.repository
		LOG.debug(fname) {"content size=#{content.length} repos=#{repos}"}
		if content.length>0
			f = File.open(repos, "wb")
			begin
				f.puts(content)
			rescue Exception => e
				e.backtrace.each {|x| LOG.error x}
				raise Exception.new "Error writing in server file #{repos}:#{e}"
			end
		f.close
		end
		#LOG.debug(fname) {"ecriture terminee"}
	end

	#
	# creation ou deplacement du repertoire du volume
	# - file_systeme: creation sur le disque du serveur suivant le chemin complet
	# - fog:
	# - database: creation de la table de nom=name
	def create_volume_dir(volume, olddirname)
		fname= "#{self.class.name}.#{__method__}"
		vol_dir_name=volume.dir_name
		LOG.debug(fname) {"olddirname=#{olddirname} vol_dir_name=#{vol_dir_name}"}
		ret=nil
		stat=::File::Stat.new(vol_dir_name)
		unless stat.directory?
			begin
				FileUtils.mkdir_p(vol_dir_name)
				ret=vol_dir_name
			rescue Exception => e
				volume.errors.add :base , e.inspect
				LOG.error(fname) {"mkdir.self.directory failed:#{e.inspect}"}
				ret=nil
			end
		end
		if(ret!=nil && olddirname != nil && olddirname != vol_dir_name)
			dirfrom = olddirname
			if(File.exists?(dirfrom))
				dirto=vol_dir_name
				if(dirto != dirfrom)
					begin
						dirvolto=File.dirname(dirto)
						LOG.debug(fname) {"changement de repertoire de #{dirfrom} to #{dirvolto}"}
						FileUtils.mv(Dir.glob(File.join(dirfrom,"*")), dirto, :force => true)
						#dir = File.join(volume.directory,self.name)
						ret = dirto
					rescue Exception => e
						LOG.error(fname) {"FileUtils.mv(#{dirfrom}, #{dirto}) failed:#{e.inspect}"}
						ret=nil
					end
				end
			else
				LOG.info(fname) {"File.exists?(#{dirfrom}):#{File.exists?(dirfrom)}"}
				ret=nil
			end
		else
			#LOG.info(fname) {"creation du volume"}
			dir = vol_dir_name
			stat=::File::Stat.new(dir)
			unless stat.directory?
				begin
					FileUtils.mkdir_p(dir)
					ret = dir
				rescue Exception => e
					volume.errors.add(:base, e.inspect)
					ret=nil
				end
			else
			ret = dir
			end
		end
		#LOG.debug(fname) {"ret=#{ret}"}
		return ret
	end

	def delete_volume_dir(volume)
		fname= "#{self.class.name}.#{__method__}"
		if File.exists? volume.dir_name
			begin
				strm = FileUtils.remove_dir volume.dir_name
			rescue Exception => e
			#e.backtrace.each {|x| puts x}
				LOG.debug(fname) {"volume.destroy_volume:error="+e.inspect}
				volume.errors.add(:base, I18n.t(:check_volume_no_rmdir, :name => volume.name, :dir => volume.directory))
			strm=false
			end
		else
			volume.errors.add(:base,I18n.t(:check_volume_no_dir, :name => volume.name, :dir => volume.directory))
		#le repertoire n'existe pas, c'est pas grave
		strm=true
		end
		ret=strm
		#LOG.debug(fname) {"ret=#{ret}"}
		ret
	end

	def remove_files(datafile)
		fname= "#{self.class.name}.#{__method__}"
		dir = datafile.dir_repository
		#puts "datafile.remove_files:"+dir
		if File.exists?(dir)
			Dir.foreach(dir) { |file|
				repos=File.join(dir,file)
				#LOG.debug(fname) {"datafile.remove_files:file="+repos}
				if File.file?(repos)
					File.unlink(repos)
				end
			}
			Dir.rmdir(dir)
		end
	end

	def files_list(volume, purge=false)
		fname= "#{self.class.name}.#{__method__}"
		path=volume.dir_name
		files_system=[]
		Pathname.glob(path + "/**/*") do |dir|
			#LOG.debug(fname) {"dir/file=#{dir}"}
			if dir.file?() then
				stat=File.stat(dir)
				#LOG.debug(fname){"\tstat:#{stat.inspect}"}
				params = fields_from_path(dir)
				params["protocol"]=self.protocol
				params["size"]=stat.size
				params["acceded_at"]=stat.atime
				params["created_at"]=stat.ctime
				params["updated_at"]=stat.mtime
				params["domain"]=""
				params["id"] = buildFileId(dir)
				dodel=false
				if(purge==true )
					is_used = is_used?(volume, params)
					#LOG.debug(fname){"\tfile:#{params.inspect} is_used?=#{is_used}"}
					if(!is_used)
						delete_file(params["id"])
					dodel=true
					end
				end
				unless dodel
					sylrplmfile=SylrplmFile.new(params)
				files_system<<sylrplmfile
				end
			end
		end
		files_system
	end

	# /media/miroir/0-0-0-0/deve/files01/Datafile/DF0000000056/_._1_._add_forum.png
	def fields_from_path(path)
		fname= "#{self.class.name}.#{__method__}"
		ret={}
		# /media/miroir/0-0-0-0/deve/files01/Datafile/DF0000000056
		dir=File.dirname(path)
		# _._1_._add_forum.png
		file=File.basename(path)
		#LOG.debug(fname) {"dir=#{dir} file=#{file}"}
		# add_forum.png
		ret["filename"]=::Datafile.filename_from_file(file)
		# 1
		ret["revision"]=::Datafile.revision_from_file(file)
		# DF0000000056
		datafile=File.basename(dir)
		# /media/miroir/0-0-0-0/deve/files01/Datafile
		dir=File.dirname(dir)
		# Datafile/DF0000000056
		ret["datafile_model"]=File.basename(dir)
		ret["datafile"]=datafile
		# /media/miroir/0-0-0-0/deve/files01
		ret["volume_dir"]=File.dirname(dir)
		ret
	end

	def delete_file(file_id)
		fname= "#{self.class.name}.#{__method__}"
		#LOG.debug(fname) {"file_id=#{file_id}"}
		fid = splitId(file_id)
		fullpath=fid[:fullpath]
		LOG.debug(fname) {"fullpath=#{fullpath} file?:#{File.file?(fullpath)}"}
		if File.file?(fullpath)
			File.unlink(fullpath)
		end
	end

	########################################################################
	# protocol calls end
	########################################################################
	def splitId(id)
		id=super(id)
		fields = id.split(::SylrplmFile::FILE_SEP_ID)
		ret={:protocol => fields[0], :fullpath => fields[1]}
	end

	def buildFileId(fullpath)
		super("#{protocol}#{::SylrplmFile::FILE_SEP_ID}#{fullpath}")
	end

	protected

	def directory_exists?(adir)
		File.exists?(adir)
	end

	def directories(purge = false)
		fname= "#{self.class.name}.#{__method__}"
	# list directories
	end

	def is_used?(volume, params)
		fname= "#{self.class.name}.#{__method__}"
		#protocol, size, id, domain, datafile_model, datafile, revision, filename, created_at, updated_at
		#/home/syl/trav/rubyonrails/sylrplm-data/0-0-0-0/deve/vollocal01/Datafile/DF0000000017
		datafiles = Datafile.find_by_ident_and_revision_and_filename(params["datafile"], params["revision"], params["filename"])
		ret = !datafiles.nil?
		#LOG.debug(fname){"ret=#{ret}"}
		ret
	end

	def directory(directory_key)

	end

	def file(directory_key, file_key)

	end

	# upload d'un fichier
	def upload_file(directory_key, file_key, local_filename)
		# upload
	end

	# upload d'un contenu
	def upload_content(directory_key, file_key, content)
		#puts "sylrplm_fog.upload_content:"+directory_key+" file_key="+file_key
		# upload
	end

	def update(directory_key, file_key, local_filename)

	end

	def retrieve(directory_key, file_key)
		#puts "sylrplm_fog.retrieve("+directory_key+","+ file_key+")"
		# get the resume file

	end

	def backup(directory)
		# copy each file to local disk
	end

	def update_file(fog_file, local_filename)
	end

	def self.remove_repository(dirkey)
		fname= "#{self.class.name}.#{__method__}"
		LOG.info(fname) {"deleting dir:#{dirkey}"}
	end

	def protocol
		"file_system"
	end

end