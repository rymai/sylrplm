class SylrplmFile
	public

	attr_reader :id, :protocol, :volume_dir, :datafile_model, :datafile, :filename, :revision, :acceded_at, :created_at, :updated_at, :size, :domain

	private

	attr_writer :id, :protocol, :volume_dir, :datafile_model, :datafile, :filename, :revision, :acceded_at, :created_at, :updated_at, :size, :domain
	FILE_SEP_ID="#_#"
	public
	def initialize(*args)
		fname = "#{self.class.name}.#{__method__}"
		LOG.info(fname) {"args=#{args.inspect}"}
		params = args[0]
		self.protocol = params["protocol"]
		self.volume_dir = params["volume_dir"]
		self.datafile_model = params["datafile_model"]
		self.datafile = params["datafile"]
		self.filename = params["filename"]
		self.revision = params["revision"]
		self.acceded_at = params["acceded_at"]
		self.created_at = params["created_at"]
		self.updated_at = params["updated_at"]
		self.size = params["size"]
		self.domain = params["domain"]
		self.id = params["id"]
		#LOG.info (fname) {"params[id]=#{params["id"]} key=#{self.id}"}
		LOG.info(fname) {"file=#{self.inspect}"}
	end

	private

	def key=(val)
		fname = "#{self.class.name}.#{__method__}"
		#LOG.info (fname) {"val=#{val}"}
	end

end