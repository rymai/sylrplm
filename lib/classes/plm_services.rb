class PlmServices

	@@plmcache={}

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
			LOG.error (fname){"Type #{type} bad formatted}"}
			nil
		end
	end

	def self.get_object(type, id )
		fname = "PlmServices.#{__method__}(#{type},#{id})"
		# part devient Part
		typec = "::#{type.camelize}"
		ret = nil
		begin
			mdl = eval typec
		rescue Exception => e
			begin
				typecr ="::Ruote::Sylrplm#{typec}"
				mdl = eval typecr
			rescue Exception => er
				LOG.error(fname) {"eval #{typec}=>#{e.message} , #{typecr}=>#{er.message}"}
				stack=""
				cnt=0
				e.backtrace.each do |x|
					if cnt<10
						stack+= x+"\n"
					end
					cnt+=1
				end
				LOG.error(fname) {"===================== stack=\n#{stack}\n====================================================="}
			end
		end
		unless mdl.nil?
			begin
				ret = mdl.find(id)
			rescue Exception => e
				LOG.error{fname+"====================="+e.message}
				stack=""
				cnt=0
				e.backtrace.each do |x|
					if cnt<10
						stack+= x+"\n"
					end
					cnt+=1
				end
				LOG.error (fname) {"--------------------- stack=\n#{stack}\n -------------------------"}
			end
		end
		LOG.debug (fname){"object not found}"} if ret.nil?
		ret
	end

	# return all or a subset of plm properties
	# props = PlmServices.get_properties
	# props_tree = PlmServices.get_properties("tree")
	# props_user = PlmServices.get_properties("user_default")
	def self.get_properties(atype_ident = nil)
		fname="PlmServices.#{__method__}"
		types = ::Typesobject.find_all_by_forobject(::SYLRPLM::PLM_PROPERTIES, :order => :name)
		ret = {}
		types.each do |typ|
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
					#LOG.debug(fname) {"prop_name=#{prop_name} key=#{key}, value=#{value} ret=#{ret}"}
				ret_key = key
				break
				else
					#LOG.debug(fname) {"prop_name=#{prop_name} key=#{key}, value=#{value} not found"}
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
						LOG.warn (fname) {"stack pour information sur l appelant a get_property=\n#{stack}"}
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
			puts "%TODO_TRANSLATE%:#{defo} stack below to see where it is called"
			if(1==1)
				begin
					a=1/0
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
					LOG.warn (fname) {"For information on translate missing: stack=\n#{stack}"}
				end
			end
		end
		LOG.debug(fname) {"key='#{key}', argums='#{argums}' ret=#{ret}"} if ret.empty?
		ret
	end


end