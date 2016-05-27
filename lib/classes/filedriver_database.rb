require 'classes/filedriver'

class FiledriverDatabase < Filedriver

	private
	def initialize
		puts "FiledriverDatabase.initialize"
	end

	public

	########################################################################
	# protocol calls begin
	########################################################################
	def dir_datafile(datafile)
		fname= "#{self.class.name}.#{__method__}"
		# datafile dir is the table name
		ret="#{vol_table_name(datafile.volume)}"
		#LOG.info(fname) {"datafile=#{datafile} ret=#{ret}"}
		ret
	end

	# renvoie les differentes revisions du fichier existantes dans le repository
	def revisions_files(datafile)
		fname= "#{self.class.name}.#{__method__}"
		records =	ActiveRecord::Base.connection.execute("SELECT filename FROM \"#{datafile.dir_repository}\" WHERE datafile = '#{datafile.ident}'")
		ret=[]
		records.each do |record|
			ret << record["filename"]
		end
		#LOG.debug(fname) {"ret=#{ret}"}
		ret
	end

	# full path of the file
	def repository(datafile)
		fname= "#{self.class.name}.#{__method__}"
		ret=""
		unless datafile.filename.nil?
			ret = "#{datafile.filename_repository}"
		end
		ret
	end

	# renvoie un repertoire dans lequel seront uploader les fichiers
	def create_directory(datafile)
		fname= "#{self.class.name}.#{__method__}"
		#LOG.debug(fname) {"datafile=#{datafile}"}
		true
	end

	def write_file(datafile, content)
		fname= "#{self.class.name}.#{__method__}"
		#LOG.debug(fname) {"content size=#{content.length} encodage=#{datafile.volume.encode}"}
		ret=true
		if content.length>0
			table=datafile.dir_repository
			# encode = ActiveSupport::Base64.encode64
			#
			content_encode=transform_content(datafile, content)
		end
		unless content_encode.nil?
			ActiveRecord::Base.connection.commit_db_transaction() ;
			begin
				cmd="INSERT INTO \"#{table}\"  (datafile,filename,revision,content,domain,size)"
				cmd+=" VALUES ('#{datafile.ident}','#{datafile.filename}','#{datafile.revision}','#{content_encode}','#{datafile.domain}',#{content.length})"
				#tres long LOG.debug(fname) {"cmd=#{cmd}"}
				ret=ActiveRecord::Base.connection.execute(cmd)
			rescue Exception=>e
				LOG.warn(fname) {"Warning INSERT ret=#{ret} e=#{e.message[0,100]}, because this file exists, then, we UPDATE"}
				cmd="UPDATE #{table} set content='#{content_encode}' where datafile='#{datafile.ident}' and filename='#{datafile.filename}' and revision='#{datafile.revision}'"
				#tres long LOG.debug(fname) {"cmd=#{cmd}"}
				begin
					ret=ActiveRecord::Base.connection.execute(cmd)
					ret=true
					#LOG.debug(fname) {"Success update ret=#{ret} "}
				rescue Exception=>e
					LOG.debug(fname) {"Error update ret=#{ret} e=#{e.message}"}
					msg="PG::Error: ERROR:  unterminated quoted string"
					msg=e.message[0,30] if e.message.index(msg).nil?
					datafile.errors.add(:base,"Exception during update:#{msg}")
				ret=false
				end
			end
			#LOG.debug(fname) {"apres insert ou update ret=#{ret}"}
			if ret
				begin
					content_decode = read_file(datafile)
					unless content_decode.nil?
						st =  content_decode.length==content.length
						st =  content_decode==content if st
						#LOG.debug(fname) {"encode/decode #{content.size} / #{content_encode.size} / #{content_decode.size}=#{st}"}
						unless st
							ret = false
							datafile.errors.add(:base,I18n.translate('activerecord.errors.messages.datafile_write_bad_format', :filename=>datafile.filename))
						end
					else
						ret = false
						datafile.errors.add(:base,"Error reading the file #{datafile.filename}")
					end
				rescue Exception => e
					LOG.error(fname){"Exception during write_file:to_s=#{e.message}"}
					unless e.message.index("PG::Error: ERROR:").nil?
						datafile.errors.add(:base,I18n.translate('activerecord.errors.messages.datafile_write_bad_format', :filename=>datafile.filename))
					else
						datafile.errors.add(:base,"Exception during write_file")
					end
					e.backtrace.each {|x| LOG.error x}
				ret=false
				end
			end
		ret
		end

		ret
	end

	def read_file(datafile)
		fname= "#{self.class.name}.#{__method__}"
		cmd="SELECT * FROM \"#{datafile.dir_repository}\" WHERE datafile = '#{datafile.ident}' AND filename='#{datafile.file_fullname}' AND revision='#{datafile.revision}'"
		LOG.debug(fname) {"cmd=#{cmd}"}
		data=nil
		begin
			records = ActiveRecord::Base.connection.execute(cmd)
			dsize=records.fsize(records.fnumber("content"))
			LOG.debug(fname) {"records(#{dsize})=#{records.fields} records.ntuples=#{records.ntuples}"}
			#records.each {|tuple| LOG.debug(fname){"#{tuple.inspect}"}}
			if records.ntuples == 1
				content = records[0]["content"]
				#ActiveSupport::Base64.decode64(data)
				data=untransform_content(datafile, content)
				LOG.debug(fname) {"data size=#{data.size}"}
			else
				LOG.debug(fname) {"data=nil"}
				data=nil
			end
		rescue Exception => e
			LOG.error(fname){"Exception during read_file:#{e.message}"}
			datafile.errors.add(:base,"Exception during read_file:#{e.message}")
			e.backtrace.each {|x| LOG.error x}
		end
		data
	end

	def remove_files(datafile)
		fname= "#{self.class.name}.#{__method__}"
		ActiveRecord::Base.connection.execute("DELETE FROM #{datafile.dir_repository} WHERE datafile = '#{datafile.ident}'")
	end

	def files_list(volume, purge=false)
		fname= "#{self.class.name}.#{__method__}"
		files=[]
		begin
			table_name=vol_table_name(volume)
			cmd="SELECT * FROM \"#{table_name}\""
			records = ActiveRecord::Base.connection.execute(cmd)
			dsize=records.fsize(records.fnumber("content"))
			#LOG.debug(fname) {"cmd=#{cmd} records=(#{dsize})=#{records.fields}:#{records.count}"}
			records.each {|tuple|
				tuple.delete("content")
				tuple["id"]=buildFileId(table_name, tuple["id"])
				tuple["volume_dir"]=table_name
				tuple["protocol"]=self.protocol
				#LOG.debug(fname) {"tuple=#{tuple}"}
				dodel=false
				if(purge==true )
					is_used = is_used?(tuple)
					#LOG.debug(fname){"\tfile:#{tuple.inspect} is_used?=#{is_used}"}
					if(!is_used)
						delete_file(tuple["id"])
					dodel=true
					end
				end
				#LOG.debug(fname) {"file=#{tuple} dodel=#{dodel}"}
				unless dodel
					file=SylrplmFile.new(tuple)
				files<<file
				end
			}
		rescue Exception=>e
			cmd="Exception during files_list:#{e.message}"
			LOG.error(fname){cmd}
			volume.errors.add(:base,cmd)
			e.backtrace.each {|x| LOG.error x}
		end
		files
	end

	def delete_file(id)
		fname= "#{self.class.name}.#{__method__}"
		fid = splitId(id)
		cmd="DELETE FROM #{fid[:table_name]} WHERE id='#{fid[:file_id]}'"
		LOG.debug(fname){"cmd=#{cmd}"}
		ActiveRecord::Base.connection.execute(cmd)
	end

	########################################################################
	# protocol calls end
	########################################################################
	def splitId(id)
		id=super(id)
		fields = id.split(::SylrplmFile::FILE_SEP_ID)
		ret={:protocol => fields[0], :table_name => fields[1], :file_id => fields[2]}
	end

	def buildFileId(table_name, file_id)
		super("#{protocol}#{::SylrplmFile::FILE_SEP_ID}#{table_name}#{::SylrplmFile::FILE_SEP_ID}#{file_id}")
	end

	protected

	def directory_exists?(adir)
		# directory=table.datafile
	end

	def is_used?(tuple)
		fname= "#{self.class.name}.#{__method__}"
		#key_dir=volfog01.datafile.df00000000031
		#TODO remplacer Datafile.find par (eval datafile_model) pour permettre le changement de nom du modele des datafiles
		datafiles = Datafile.find_by_ident_and_revision_and_filename(tuple["datafile"], tuple["revision"], tuple["filename"])
		ret = !datafiles.nil?
		#LOG.debug(fname){"ret=#{ret}"}
		ret
	end

	def directory(directory_key)
		ret=directories.get(directory_key)
		#puts "sylrplm_fog.directory("+directory_key+")="+ret.inspect
		ret
	end

	def file(directory_key, file_key)
		#puts "sylrplm_fog.file("+directory_key+","+ file_key+")"
		#puts "sylrplm_fog.file("+directory_key+","+ file_key+")="+ret.inspect
		ret
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

end