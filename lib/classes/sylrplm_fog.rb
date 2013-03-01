# acces au serveur de fichier fog sur le cloud
require 'fog'

class SylrplmFog

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
		if @@instance.nil?
			@@instance = SylrplmFog.new
			# create a connection
			@@instance.storage = Fog::Storage.new(
			{
				:provider                 => 'AWS',
				:aws_secret_access_key    => SYLRPLM::FOG_ACCESS_KEY,
				:aws_access_key_id        => SYLRPLM::FOG_ACCESS_KEY_ID
			})
		end
		#puts "SylrplmFog.instance:"+@@instance.inspect
		return @@instance
	end

	# renvoie un repertoire dans lequel seront uploader les fichiers
	def create_directory(directory_key)
		unless directory_exists?(directory_key)
			directory = self.storage.directories.create(
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

	def directory_exists?(adir)
		dirs = directories
		dirs.include? adir
	end

	def directories(log=false)
		# list directories
		#puts "sylrplm_fog.directories:"+self.storage.inspect
		ret=[]
		begin
			ret=self.storage.directories
			if log
				puts "sylrplm_fog.directories="
				ret.each do |ddd|
					puts "directory:"+ddd.inspect
					ddd.files.each do |s3_file|
						puts "\tfile:"+s3_file.inspect
					end
				end
				puts ret.inspect
			end
		rescue Exception=>e
			puts "fog access error:#{e}"
		end
		ret
	end

	def directory(directory_key)
		ret=directories.get(directory_key)
		#puts "sylrplm_fog.directory("+directory_key+")="+ret.inspect
		ret
	end

	def file(directory_key, file_key)
		#puts "sylrplm_fog.file("+directory_key+","+ file_key+")"
		ret=directory(directory_key).files.get(file_key)
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
		#puts "sylrplm_fog.upload_content:"+directory_key+" file_key="+file_key
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
		fog_file
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
		fname= "#{self.class.name}.#{__method__}"
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

	def all

	end
#private_class_method :new
end