
class Filedriver

	private
	def initialize
		puts "Filedriver.initialize"
	end

	public

	########################################################################
	# protocol calls begin
	########################################################################

	########################################################################
	# protocol calls end
	########################################################################
	def splitId(id)
		id.gsub("##",".")
	end

	def buildFileId(id)
		id.gsub(".","##")
	end

	def self.driver_from_file_id(file_id)
		protocol=protocol_from_file_id(file_id)
		driver_from_procotol(protocol)
	end

	def self.protocol_from_file_id(file_id)
		fields=file_id.split(::SylrplmFile::FILE_SEP_ID)
		fields[0]
	end

	def self.driver_from_procotol(protocol)
		ret=(eval ("filedriver_#{protocol}".camelize)).instance
	end

	def transform_content(datafile, content)
		fname= "#{self.class.name}.#{__method__}"
		#LOG.debug (fname) {"debut:size=#{content.length}"}
		#LOG.debug (fname) {"debut:#{content}"}
		begin
			unless datafile.volume.compress.blank?
				#LOG.debug (fname) {"code datafile.volume.compress='#{datafile.volume.compress}'"}
				#compress = zip_content(content, datafile.filename)
				@content=content
				@filename=datafile.filename
				#LOG.debug (fname) {"@filename=#{@filename} @content=#{@content}"}
				#require 'zip/zip'
				#stringio = Zip::ZipOutputStream::write_buffer(::StringIO.new("@filename"))  do |zio|
				#	zio.put_next_entry(@filename)
				#	zio.write @content
				#end
				#stringio.rewind
				#compress = stringio.sysread
				compress = eval datafile.volume.compress
				LOG.debug (fname) {"compress:size=#{compress.length}"}
			#LOG.debug (fname) {"compress=#{compress}"}
			else
			compress = content
			end
			unless datafile.volume.encode.blank?
				# ActiveSupport::Base64.encode64
				#encode_fields=datafile.volume.encode.split(".")
				#content_encode=(eval encode_fields[0]).send(encode_fields[1], compress)
				@content=compress
				@filename=datafile.filename
				#LOG.debug (fname) {"code datafile.volume.encode='#{datafile.volume.encode}'"}
				content_encode = eval datafile.volume.encode
				LOG.debug (fname) {"encode:size=#{content_encode.length}"}
			#LOG.debug (fname) {"encode=#{content_encode}"}
			else
			content_encode = compress
			end
		rescue Exception=>e
			msg="Exception during transformation(encode+compress):#{e.message}"
			LOG.error (fname){msg}
			datafile.errors.add_to_base(msg)
			e.backtrace.each {|x| LOG.error x}
			content_encode=nil
		end
		content_encode
	end

	def untransform_content(datafile, data)
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug (fname) {"data:size=#{data.length}"}
		#LOG.debug (fname) {"data=#{data}"}
		begin
			unless datafile.volume.decode.blank?
				# ActiveSupport::Base64.decode64
				#decode_fields=datafile.volume.decode.split(".")
				#data=(eval decode_fields[0]).send(decode_fields[1], data)
				@content=data
				@filename=datafile.filename
				#LOG.debug (fname) {"datafile.volume.decode=#{datafile.volume.decode}"}
				data = eval datafile.volume.decode
				LOG.debug (fname) {"decode:size=#{data.length}"}
			end
			unless datafile.volume.decompress.blank?
				#decompress = unzip_content(data, datafile.filename)
				@content=data
				@filename=datafile.filename
				#LOG.debug (fname) {"datafile.volume.decompress=#{datafile.volume.decompress} , data.length:#{data.length}"}
				#LOG.debug (fname) {"@content=#{@content}"}
				decompress = eval datafile.volume.decompress
				LOG.debug (fname) {"decompress:size=#{decompress.length}"}
			else
			decompress = data
			end
		rescue Exception=>e
			msg="Exception during untransformation(decode+decompress):#{e.message}"
			LOG.error (fname){msg}
			datafile.errors.add_to_base(msg)
			e.backtrace.each {|x| LOG.error x}
			decompress=nil
		end
		#LOG.debug (fname) {"decompress=#{decompress}"}
		decompress
	end

end