require 'ruote/sylrplm/sylrplm'
require 'zip'

class PlmServices
	include ::Ruote::Sylrplm
	@@plmcache={}

	def self.zip_in_stringio(filename, content)
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug(fname) {"filename=#{filename } content=#{content.size}"}
		stringio = Zip::OutputStream::write_buffer(::StringIO.new) do |zio|
		zio.put_next_entry(filename)
		  zio.write content
		end
		stringio.rewind
		binary_data = stringio.sysread
	end

	def self.unzip_stringio(content)
		fname= "#{self.class.name}.#{__method__}"
		ret=nil
		unless content.blank?
			LOG.debug(fname) {"content=#{content.size}"}
			stringio=::StringIO.new(content)
			LOG.debug(fname) {"stringio=#{stringio.inspect}"}
			Zip::InputStream.open(stringio) do |zio|
				LOG.debug(fname) {"zio=#{zio}"}
				while (entry = zio.get_next_entry)
					LOG.debug(fname) {"zio.read:#{entry.name}"}
					ret = zio.read
				end
			end
		else
			raise Exception.new "Content to unzip is null or empty"
		end
		ret
	end

	def self.get_property_cache(prop_name)
		fname = "PlmServices.#{__method__}"
		ret=nil
		prop_name=prop_name.to_s
		unless @@plmcache["property"].nil?
			#LOG.debug(fname) {"prop_name=#{prop_name} #{@@plmcache["property"].count} =#{@@plmcache["property"][prop_name]} properties in cache:#{@@plmcache["property"]}"}
			ret=@@plmcache["property"][prop_name]
		end
		LOG.debug(fname) {"propName=#{prop_name} ret=#{ret}"}
		ret
	end

	def self.set_property_cache(prop_name, value)
		fname = "PlmServices.#{__method__}"
		prop_name=prop_name.to_s
		if @@plmcache["property"].nil?
			@@plmcache["property"]={}
		end
		@@plmcache["property"][prop_name]=value
	#LOG.debug(fname) {"prop_name=#{prop_name} value=#{value} #{@@plmcache["property"].count} properties in cache"}
	end

	# reset the cache of properties
	def self.reset_property_cache
		fname = "PlmServices.#{__method__}"
		#LOG.debug(fname) {"reset cache"}
		@@plmcache["property"]=nil
	end

	# reset the cache
	def self.reset_cache
		@@plmcache=nil
	end

	def self.isEmail(str)
		str.match(/\A(\S+)@(.+)\.(\S+)\z/)
	end

	def self.get_object_by_mdlid(mdlid)
		fields = mdlid.split(".")
		if fields.size == 2
			get_object(fields[0], fields[1])
		else
			LOG.error(fname){"Type #{type} bad formatted}"}
			nil
		end
	end

	def self.get_object(type, id )
		fname = "PlmServices.#{__method__}"
		LOG.debug(fname){"type=#{type},id=#{id}"}
		# part devient Part
		typec = "::#{type.camelize}"
		#typec=type.camelize
		ret = nil
		begin
			mdl = eval typec
			#mdl=mdl[0,index(mdl,":")]
			LOG.debug(fname) {"mdl=eval #{typec}=#{mdl}"}
		rescue Exception => e1
			LOG.error(fname) {"error1:#{typec}=>:#{e1.message} "}
			begin
				typecr ="::Ruote::#{typec}"
				mdl = eval typecr
			rescue Exception => e2
				LOG.error(fname) {"error2:#{typecr}=>#{e2.message}"}
				begin
					typecr ="::Ruote::Sylrplm#{typec}"
					mdl = eval typecr
				rescue Exception => e3
					LOG.error(fname) {"error3:#{typecr}=>#{e3.message}"}
					if(true)
						stack=""
						cnt=0
						e3.backtrace.each do |x|
							if cnt<10
								stack+= x+"\n"
							end
							cnt+=1
						end
						LOG.error(fname) {"stack=\n#{stack}\n"}
					end
				end
			end
		end
		#
		unless mdl.nil?
			if RuoteKit.engine.nil?
				PlmServices.ruote_init
		    end
			begin
				if(mdl.to_s=="Ruote::Sylrplm::Process" || mdl.to_s=="Process")
				ret=::RuoteKit.engine.process(id)
				else
				ret = mdl.find(id)
				end
			rescue Exception => e
				LOG.error(fname) {"error:#{e.message}"}
				if(true)
					stack=""
					cnt=0
					e.backtrace.each do |x|
						if cnt<10
							stack+= x+"\n"
						end
						cnt+=1
					end
					LOG.error(fname) {"stack=\n#{stack}\n"}
				end
			end
		end
		#LOG.debug(fname){"object not found}"} if ret.nil?
		ret
	end

	# return all or a subset of plm properties
	# props = PlmServices.get_properties
	# props_tree = PlmServices.get_properties("tree")
	# props_user = PlmServices.get_properties("user_default")
	def self.get_properties(atype_ident = nil)
		fname="PlmServices.#{__method__}"
		#rails4 types = ::Typesobject.find_all_by_forobject(::SYLRPLM::PLM_PROPERTIES, :order => :name)
		types = ::Typesobject.order(:name).where(:forobject=>::SYLRPLM::PLM_PROPERTIES).to_a
		if  types.is_a?(Array)
		array_types=types
		else
		array_types=[]
		array_types << types
		end
		ret = {}
		array_types.each do |typ|
			LOG.debug(fname) {"atype_ident=#{atype_ident} type=#{typ}"}
			ident = "#{typ.name}"
			if atype_ident.nil?
			# all properties
			ret[ident] = typ.get_fields_values()
			else
			# just a type
				if ident == atype_ident
				ret[ident] = typ.get_fields_values()
				end
			end
		end
		#LOG.debug(fname) {"atype_ident=#{atype_ident} ret=#{ret}"}
		ret
	end

	#
	#== Role: return a property value
	#
	# == Arguments
	# * +prop_name+ - The name of the needed property
	# * +atype_ident+ - the group of properties given by the Typesobject name:
	# 	- user_default
	# 	- tree
	# 	- objects_names
	# 	- others
	# 	- form_values
	# == Usage
	# 	d=::PlmServices.get_property("THEME_DEFAULT","user_default") : "white"
	# 	d=:: PlmServices.get_property("HELP_SUMMARY_LEVEL") : "3"
	# === Result
	# 	see above
	# == Impact on other components
	#
	def self.get_property(prop_name, atype_ident=nil)
		fname = "PlmServices.#{__method__}"
		LOG.debug(fname) {">>>>prop_name=#{prop_name}"}
		ret=get_property_cache(prop_name)
		unless  ret.nil?
			#LOG.debug(fname) {"<<<<prop_name=#{prop_name}, atype_ident=#{atype_ident}, ret=#{ret} found in cache"}
			else
			props = get_properties(atype_ident)
			ret=nil
			ret_key=nil
			prop_name=prop_name.to_s.strip
			props.each do |key, value|
			#LOG.debug(fname) {"prop_name=#{prop_name} key=#{key}, value=#{value}"}
			#value=val[::Models::SylrplmCommon::TYPE_VALUES_VALUE][prop_name]
				unless value.nil? || value[prop_name].nil?
					ret = value[prop_name][::Models::SylrplmCommon::TYPE_VALUES_VALUE]
					LOG.debug(fname) {"prop_name=#{prop_name} key=#{key}, value=#{value} ret=#{ret}"}
				ret_key = key
				break
				else
					LOG.debug(fname) {"prop_name=#{prop_name} key=#{key}, value=#{value} not found"}
				end
			end
			#
			if ret.nil?
				# the property is not in a typesobject, we search in SYLRPLM variables
				begin
					var = "::SYLRPLM::#{prop_name}"
					ret = eval var
					#LOG.warn(fname) {"variable #{prop_name} does not exists in TypesObjects/#{atype_ident} but found in config file sylrplm.rb"}
				rescue Exception=>e
					LOG.error(fname) {"variable #{var} does not exists in TypesObjects/#{atype_ident} and not found in config file sylrplm.rb"}
					begin
						s=100/0
					rescue Exception => e
						stack=""
						e.backtrace.each do |x|
							stack+= x+"\n"
						end
					####LOG.warn(fname) {"stack pour information sur l appelant a get_property=\n#{stack}"}
					end
				end
				LOG.debug(fname) {"prop_name=#{prop_name}, atype_ident=#{atype_ident}, ret=#{ret} found in SYLRPLM variables"}
			else
				LOG.debug(fname) {"prop_name=#{prop_name}, atype_ident=#{atype_ident}, ret=#{ret} found in #{ret_key} properties"  }
			end
			set_property_cache(prop_name, ret)
		end
		LOG.debug(fname) {"<<<<prop_name=#{prop_name}, ret=#{ret}"  }
		ret
	end

	def self.set_property( atype_ident, prop_name, value)
		fname = "PlmServices.#{__method__}"
		params={}
		params[:forobject] = ::SYLRPLM::PLM_PROPERTIES
		params[:name] = atype_ident
		params[:fields]={prop_name=>value}.to_json
		type=::Typesobject.find_by_name(atype_ident)
		if type.nil?
		type=::Typesobject.new(params)
		st=type.save
		else
		st=type.update_attributes(params)
		end
		LOG.debug(fname) {"st=#{st}, atype_ident=#{atype_ident}, name=#{type.name}, fields=#{type.fields}, error=#{type.errors.full_messages}"}
		type
	end

	#
	# execute a ruby bloc
	#
	def self.exec_bloc(bloc, code)
		fname = "PlmServices.#{__method__}"
		#LOG.debug(fname) {"bloc=#{bloc} , code=#{code}"}
		ret=eval code
		#LOG.debug(fname) {"ret=#{ret}"}
		ret
	end

	# 1- [["language_fr"]]
	#
	#
	def self.translate(*args)
		fname = "PlmServices.#{__method__}"
		#LOG.debug(fname) {"translate:args = '#{args}'"}
		akey=args[0]
		unless args[1].nil?
		argums=args[1]
		else
			argums={}
		end
		if akey.is_a?(Array)
		key=akey[0]
		argums=akey[1]
		else
		key=akey
		end
		#LOG.debug(fname) {"key='#{key}', argums='#{argums}'"}
		if(Rails.env.production?)
			defo="#{key.capitalize}"
		else
			defo="%#{I18n.locale}% #{key}:"
		end
		argums={} if argums.nil?
		argums[:default]=defo
		#ret=I18n.translate(key, argums, :default=> defo)
		ret=I18n.translate(key, argums)
		if ret==defo
			# to keep logs about tranlation to do
			if(false)
				LOG.warn(fname) {"%TODO_TRANSLATE%:#{defo}"}
			else
				LOG.warn(fname) {"%TODO_TRANSLATE%:#{defo} stack below to see where it is called"}
				begin
					a=1
					b=0
					c=a/b
				rescue Exception => e
					stack=""
					nbr=0
					e.backtrace.each do |x|
						unless x.include? "plm_services.rb"
							stack+= x+"\n"
						end
						break  if nbr==6
						nbr+=1
					end
					LOG.warn(fname) {"For information on translate missing: stack=\n#{stack}"}
				end
			end
		end
		LOG.debug(fname) {"key='#{key}', argums='#{argums}' ret=#{ret}"} if ret.empty?
		ret
	end

	def self.stack(msg, level)
		fname = "PlmServices.#{__method__}"
		LOG.warn(fname) {"#{msg}: level=#{level}"}
		begin
			a=1
			b=0
			c=a/b
		rescue Exception => e
			stack=""
			nbr=0
			e.backtrace.each do |x|
				break  if nbr==level
				unless x.include? "plm_services.rb"
					stack+= x+"\n"
				nbr+=1
				end
			end
			LOG.warn(fname) {"#{msg}: stack=\n#{stack}"}
		end
	end

	# Swaps from dots to underscores
	#
	#   swapdots "0_0_1" # => "0.0.1"
	#   swapdots "0.0.1" # => "0_0_1"
	#
	# DEPRECATED since 0.9.21
	#
	def self.swapdots (s)
		s.index('.') ? s.gsub(/\./, '_') : s.gsub(/\_/, '.')
	end

	def self.to_dots (s)
		s.gsub(/\_/, '.')
	end

	def self.to_uscores (s)
		s.gsub(/\./, '_')
	end

	def self.ruote_init
		fname = "PlmServices.#{__method__}"
		ActiveRecord::Base.configurations = Rails.application.config.database_configuration
		db_config=ActiveRecord::Base.configurations[Rails.env]
		puts fname+db_config.to_s
		pg_db_config={}
		pg_db_config["dbname"]=db_config["database"]
		pg_db_config["user"]=db_config["username"]
		pg_db_config["password"]=db_config["password"]
		pg_db_config["host"]=db_config["localhost"]
		puts fname+ "pg_db_config=#{pg_db_config}"

		#puts fname+  "connection_config=#{ActiveRecord::Base.connection_config}"

		pg_connection =PG.connect(pg_db_config)
		####pg_connection =PG::Connection.open(pg_db_config)
		#pg_connection =ActiveRecord::Base.connection

		#pg_pool =ActiveRecord::Base.establish_connection(ActiveRecord::Base.configurations[Rails.env])
		#pg_connection=pg_pool.checkout
		puts fname+  "pg_connection=#{pg_connection}"
		begin
			table_name='ruote_docs'
			Ruote::Postgres.create_table(pg_connection, true, table_name)
		rescue Exception=>e
				# the table still exists, no pb
			puts fname+  "Warning:#{e}"
		end
		begin
			storage_opts={"pg_table_name" => table_name}
			ruote_storage=Ruote::Postgres::Storage.new(pg_connection, storage_opts)
			puts fname+ "ruote_storage=#{ruote_storage}"
			#
			pg_worker=Ruote::Worker.new(ruote_storage)
			RuoteKit.engine  = Ruote::Dashboard.new(pg_worker)
		rescue Exception=>e
			puts fname+  "Error:#{e}"
		end

		# By default, there is a running worker when you start the Rails server. That is
		# convenient in development, but may be (or not) a problem in deployment.
		#
		# Please keep in mind that there should always be a running worker or schedules
		# may get triggered to late. Some deployments (like Passenger) won't guarantee
		# the Rails server process is running all the time, so that there's no always-on
		# worker. Also beware that the Ruote::HashStorage only supports one worker.
		#
		# If you don't want to start a worker thread within your Rails server process,
		# replace the line before this comment with the following:
		#
		# RuoteKit.engine = Ruote::Engine.new(RUOTE_STORAGE)
		#
		# To run a worker in its own process, there's a rake task available:
		#
		#     rake ruote:run_worker
		#
		# Stop the task by pressing Ctrl+C

		unless $RAKE_TASK # don't register participants in rake tasks
			puts fname+  "RuoteKit.engine=#{RuoteKit.engine}"
		  RuoteKit.engine.register do
		    # register your own participants using the participant method
		    # Example: participant 'alice', Ruote::StorageParticipant see
		    # http://ruote.rubyforge.org/participants.html for more info
			puts fname+ "loading participants"
			# only enter this block if the engine is running
			participant 'plm', Ruote::PlmParticipant
		    # register the catchall storage participant named '.+'
		    catchall
		  end
		end
		puts fname+ "list of participants"
		RuoteKit.engine.participant_list.each { |pe| puts "#{pe}" }
		#
		# when true, the engine will be very noisy (stdout)
		RuoteKit.engine.context.logger.noisy = false
	end

	def self.file_exists?(filename)
		return File.exists?(filename)
	end

	def self.file_write(content,repos)
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
	end

	def self.file_sysread(repository)
		f = File.open(repository, "rb")
		nctot=file_size(repository)
		data = f.sysread(nctot)
		f.close
		data
	end

	def self.file_size(repository)
		nctot = File.size(repository)
	end

	def self.file_basename(filename)
		File.basename(filename)
	end

	def self.write_ouput_stream(tmpfile,tmpname,content)
		::Zip::ZipOutputStream.open(tmpfile) do |zio|
			zio.put_next_entry(tmpname)
			zio.write content
		end
	end
end