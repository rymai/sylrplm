require 'rubygems'
require 'fog'
require 'classes/filedrivers'
require 'pathname'

class Volume < ActiveRecord::Base
	include Models::SylrplmCommon

	validates_presence_of :name, :protocol
	validates_format_of :name, :with =>/^([a-z]|[A-Z]|[0-9]||[.])+$/
	validates_uniqueness_of :name

	has_many :users
	has_and_belongs_to_many :groups
	has_many :datafiles

	PROTOCOL_FILE_SYSTEM="file_system"
	PROTOCOL_FOG="fog"
	PROTOCOL_DATABASE_TEXT="database_text"
	PROTOCOL_DATABASE_BINARY="database_binary"
	FILE_REV_DELIMITER = "_._"
	DIR_DELIMITER = "."
	#
	########################################################################
	# protocol calls begin
	########################################################################
	#
	def protocol_driver
		fname= "#{self.class.name}.#{__method__}"
		ret=(eval ("filedriver_#{protocol}".camelize)).instance
		LOG.debug (fname)  {"volume=#{name} protocol=#{protocol} driver=#{ret}"}
		ret
	end

	#
	# definit et cree le repertoire du  volume, celui ci depend du protocol
	# - file_systeme: directory=repertoire sur le disque du serveur: /home/syl/trav/rubyonrails/sylrplm-data-development/vol-local-01/
	# - fog: string composee pour etre unique sur le cloud
	# - database: directory=nom de la table
	#
	def set_directory
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug (fname) {"debut old_dir_name=#{@old_dir_name}"}
		dir = protocol_driver.create_volume_dir(self,@old_dir_name)
		if dir.nil?
			ret = false
			self.errors.add_to_base I18n.t(:ctrl_object_not_created,:typeobj => I18n.t(:ctrl_volume), :ident=>self.name, :msg => nil)
		else
		ret = true
		end
		LOG.debug (fname) {"fin dir=#{dir} ret=#{ret}"}
		ret
	end

	def destroy_volume
		fname= "#{self.class.name}.#{__method__}"
		if !is_used?
			LOG.debug (fname) {"not used, protocol=#{protocol}"}
			ret = protocol_driver.delete_volume_dir(self)
			if ret
			ret = self.destroy
			else
				self.errors.add_to_base I18n.t(:check_volume_is_used, :ident=>self.name)
			end
		else
			self.errors.add_to_base I18n.t(:check_volume_is_used, :ident=>self.name)
		ret=false
		end
		LOG.debug (fname) {"ret=#{ret} errors=#{self.errors.inspect}"}
		ret
	end

	########################################################################
	# protocol calls end
	########################################################################

	def self.get_all_files(purge=false)
		fname= "#{self.class.name}.#{__method__}"
		files_system={}
		files_database={}
		Volume.find_all.each { |vol|
			files_system[vol.name]=vol.protocol_driver.files_list(vol,purge) if vol.protocol==::Volume::PROTOCOL_FILE_SYSTEM
			files_database[vol.name]=vol.protocol_driver.files_list(vol,purge) if vol.protocol==::Volume::PROTOCOL_DATABASE_TEXT || vol.protocol==::Volume::PROTOCOL_DATABASE_BINARY
		}
		fogfiles = {}
		fogfiles["unknown"] = FiledriverFog.instance.files_list(purge)
		#
		all_files=Hash.new
		all_files[:fog_files]=fogfiles
		all_files[:file_system_files]=files_system
		all_files[:database_files]=files_database
		LOG.debug (fname) {"files_database=#{files_database}"}
		LOG.debug (fname) {"files_system=#{files_system}"}
		LOG.debug (fname) {"fogfiles=#{fogfiles}"}
		all_files
	end

	def validate
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug (fname) {"protocol=#{protocol} directory=#{directory} old_dir_name=#{@old_dir_name}"}
		errors.add_to_base I18n.t("valid_volume_directory_needed", :protocol=>protocol) if [PROTOCOL_FILE_SYSTEM].include? protocol && directory.blank?
	end

	def initialize(params_volume=nil)
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug (fname) {"params=#{params_volume}"}
		super
		if params_volume.nil?
			self.directory = PlmServices.get_property(:VOLUME_DIRECTORY_DEFAULT)
		self.set_default_values(1)
		end
		self
	end

	def ident
		name
	end

	def self.protocol_values
		[PROTOCOL_FILE_SYSTEM, PROTOCOL_DATABASE_TEXT, PROTOCOL_DATABASE_BINARY, PROTOCOL_FOG].sort
	end

	def self.find_all
		find(:all, :order=>"name")
	end

	def self.find_first
		find(:first, :order=>"name")
	end

	def is_used?
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug (fname) {"users.count=#{users.count} datafiles.count=#{datafiles.count}"}
		self.users.count >0 || self.datafiles.count >0
	end

	def before_save
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug (fname) {"debut"}
		ret=set_directory
		LOG.debug (fname) {"fin: ret=#{ret}"}
		ret
	end

	def update_attributes(params_volume)
		fname= "#{self.class.name}.#{__method__}"
		@old_dir_name = dir_name
		#LOG.debug (fname) {"debut old_dir_name=#{@old_dir_name} params=#{params_volume}"}
		ret = super(params_volume)
		#LOG.debug (fname) {"fin apres super  old_dir_name=#{@old_dir_name} ret=#{ret}"}
		ret
	end

	def after_save
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug (fname) {"volume=#{self.inspect}"}
	end

	#
	# /home/syl/trav/rubyonrails/sylrplm-data-development/vollocal01/Datafile/
	# self.directory=/home/syl/trav/rubyonrails/sylrplm-data-development
	# env=
	def dir_name
		fname= "#{self.class.name}.#{__method__}"
		unless self.directory.blank?
			ret=File.join(self.directory, Volume.rails_env)
		else
			ret=Volume.rails_env
		end
		ret=File.join(ret, self.name)
		LOG.info (fname) {"dir_name=#{ret}"}
		ret
	end

	def self.rails_env
		File.join(Datafile::host,Rails.env[0,4])
	end

	def self.get_conditions(filter)
		filter = filters.gsub("*","%")
		ret={}
		unless filter.nil?
			ret[:qry] = "name LIKE :v_filter or description LIKE :v_filter or directory LIKE :v_filter or protocol LIKE :v_filter or to_char(updated_at, 'YYYY/MM/DD') LIKE :v_filter"
			ret[:values]={:v_filter => filter}
		end
		ret
	#conditions = ["name LIKE ? or description LIKE ? or directory LIKE ? or protocol LIKE ?"
	end

	private

	def _list_files_
		if self.protocol == PROTOCOL_FOG
			ret="files are stored in cloud by fog"
		elsif self.protocol == PROTOCOL_DATABASE_TEXT
			ret="files are stored in table"
		elsif self.protocol == PROTOCOL_DATABASE_BINARY
			ret="files are stored in table"
		else
			dir=File.join(self.directory,self.name)
			ret=""
			if (File.exists?(dir))
				Dir.foreach(dir) do |objectdir|
					if (objectdir!="." && objectdir!="..")
						dirobject=File.join(dir,objectdir)
					end
					if (File.directory?(dirobject))
						Dir.foreach(dirobject) do |iddir|
							if (iddir!="." && iddir!="..")
								dirid=File.join(dirobject,iddir)
								ret += "\ndirid="+iddir+"="+dirid
								if (File.directory?(dirid))
									files = Dir.entries(dirid)
								end
								if (files.size>2)
									ret += ":nb="+files.size.to_s+":id="+iddir
									for f in  files
										ret += ":"+f
									end
								else
									ret += "\nbad file:"+dirid
								end
							end
						end
					else
						ret+="\nbad file:"+dirobject
					end
				end
			end
		end
		ret
	end

end
