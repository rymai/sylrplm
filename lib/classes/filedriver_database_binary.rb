require 'classes/filedriver'
require 'classes/filedriver_database'

class FiledriverDatabaseBinary  < FiledriverDatabase

	private
	def initialize
		puts "FiledriverDatabaseBinary.initialize"
	end

	public

	# une seule instance car une seule connection
	@@instance = nil

	PREFIXE_TABLE="volbin_"

	def self.instance
		if @@instance.nil?
			@@instance = FiledriverDatabaseBinary.new
		end
		#puts "FiledriverDatabaseBinary.instance:"+@@instance.inspect
		return @@instance
	end

	class VolumeTablesBinary < ActiveRecord::Migration
		def self.init_table(table_name)
			puts "VolumeTablesBinary:establish_connection="+ActiveRecord::Base.establish_connection
			#rails2 database_conf=Rails::Configuration.new.database_configuration
			database_conf=Rails.application.config.database_configuration
			puts "VolumeTablesBinary:database_configuration=#{database_conf.inspect}"
			unless ActiveRecord::Base.connection.table_exists? table_name
				create_table table_name do |t|
					t.column :datafile_model, :string
					t.column :datafile, :string
					t.column :filename, :string
					t.column :revision, :string
					t.column :created_at, :timestamp
					t.column :updated_at, :timestamp
					t.column :acceded_at, :timestamp
					t.column :size, :integer
					t.column :domain, :string
				end
				if database_conf["development"]["adapter"] !=  "postgresql"
					add_column table_name , :content, :binary , :limit=> "#{PlmServices.get_property(:MAX_FILE_SIZE)}"
				else
					add_column table_name , :content, :binary
				end

				add_index table_name, [:datafile, :filename,:revision], :name=> "idx_#{table_name}_on_datafile_filename_revision", :unique => true
			end
		end

		def self.delete_table(table_name)
			fname= "#{self.class.name}.#{__method__}"
			if ActiveRecord::Base.connection.table_exists? table_name
				#LOG.debug(fname) {"table_name to drop =#{table_name}"}
				ret = drop_table table_name
			else
			ret=true
			end
			LOG.debug(fname) {"table_name=#{table_name} ret=#{ret}"}
			ret
		end

	end
	########################################################################
	# protocol calls begin
	########################################################################

	#
	# creation du repertoire du volume
	# - file_systeme: creation sur le disque du serveur suivant le chemin complet
	# - fog:
	# - database: creation de la table de nom=name
	def create_volume_dir(volume,olddirname)
		fname= "#{self.class.name}.#{__method__}"
		if !olddirname.blank? && volume.dir_name != olddirname
			ret=nil
			self.errors.add :base, "The directory of database volume can't be moved"
		else
			ret = vol_table_name(volume)
			VolumeTablesBinary.init_table(ret)
		end
		LOG.debug(fname) {"ret=#{ret}"}
		ret
	end

	def delete_volume_dir(volume)
		fname= "#{self.class.name}.#{__method__}"
		ret = VolumeTablesBinary.delete_table(vol_table_name(volume))
		LOG.debug(fname) {"ret=#{ret}"}
		ret
	end

	########################################################################
	# protocol calls end
	########################################################################
	def vol_table_name(volume)
		PREFIXE_TABLE+volume.name
	end

	def protocol
		"database_binary"
	end
end