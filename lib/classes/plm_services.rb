class PlmServices
	def self.get_object_by_mdlid(mdlid)
		fields = mdlid.split(".")
		if fields.size == 2
			get_object(fields[0], fields[1])
		else
			nil
		end
	end

	def self.get_object(type, id)
		# parts devient Part
		fname = "PlmServices.#{__method__}(#{type},#{id})"
		typec = type.camelize
		ret = nil
		begin
			mdl = eval typec
		rescue Exception => e
		#LOG.warn{fname+e.message}
			begin
				typec ="Ruote::Sylrplm::"+typec
				mdl = eval typec
			rescue Exception => e
			#LOG.error{fname+e.message}
			end
		end
		unless mdl.nil?
			begin
				ret = mdl.find(id)
			rescue Exception => e
			#LOG.error{fname+e.message}
			end
		end
		#LOG.debug (fname){"ret=#{(ret.nil? ? "" : ret.ident)}"}
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
		#LOG.debug(fname) {"atype_ident=#{atype_ident} type=#{typ}"}
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
	# == Usage
	# 	d=::PlmServices.get_property("THEME_DEFAULT","user_default") : "white"
	# 	d=:: PlmServices.get_property("HELP_SUMMARY_LEVEL") : "3"
	# === Result
	# 	see above
	# == Impact on other components
	#
	def self.get_property(prop_name, atype_ident=nil)
		fname = "PlmServices.#{__method__}"
		props = get_properties(atype_ident)
		ret=nil
		ret_key=nil
		prop_name=prop_name.to_s.strip
		props.each do |key, value|
		#LOG.debug(fname) {"key=#{key}, value=#{value}"}
			unless value.nil? || value[prop_name].nil?
			ret = value[prop_name]
			ret_key = key
			break
			end
		end
		#
		if ret.nil?
			# the property is not in a typesobject, we search in SYLRPLM variables
			begin
				var = "::SYLRPLM::#{prop_name}"
				ret = eval var
				LOG.warn(fname) {"variable #{prop_name} does not exists in TypesObjects/#{atype_ident} but found in config file sylrplm.rb"}
			rescue Exception=>e
				LOG.error(fname) {"variable #{var} does not exists in TypesObjects/#{atype_ident} and not found in config file sylrplm.rb"}
				begin
					s=100/0
				rescue Exception => e
					stack=""
					e.backtrace.each do |x|
						stack+= x+"\n"
					end
					LOG.warn (fname) {"stack=\n#{stack}"}
				end
			end
		#LOG.debug(fname) {"prop_name=#{prop_name}, atype_ident=#{atype_ident}, ret=#{ret} found in SYLRPLM variables"}
		else
		#LOG.debug(fname) {"prop_name=#{prop_name}, atype_ident=#{atype_ident}, ret=#{ret} found in #{ret_key} properties"  }
		end
		ret
	end

	def self.set_property( atype_ident, prop_name, value)
		fname = "PlmServices.#{__method__}"
		params={}
		params[:forobject] = ::SYLRPLM::PLM_PROPERTIES
		params[:name] = atype_ident
		params[:fields]={prop_name=>value}.to_json
		type=::Typesobject.new(params)
		type.save
		#LOG.debug(fname) {"prop name=#{prop_name}, type=#{type.inspect}"}
		type
	end

	# 1- [["language_fr"]]
	#
	#
	def self.translate(*args)
		fname = "PlmServices.#{__method__}"
		#LOG.debug(fname) {"args='#{args}'"}
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
			ret=I18n.translate(key, argums, :default=> "#{key.capitalize}")
		else
			defo="%#{I18n.locale}% #{key}:"
			argums={} if argums.nil?
			argums[:default]=defo
			#ret=I18n.translate(key, argums, :default=> defo)
			ret=I18n.translate(key, argums)
			if ret==defo
				# to keep logs about tranlation to do
				puts "%TODO_TRANSLATE%:#{defo} stack below to see where it is called"
				begin
					a=1/0
				rescue Exception => e
					stack=""
					e.backtrace.each do |x|
						stack+= x+"\n"
					end
					LOG.warn (fname) {"stack=\n#{stack}"}
				end
			end
		end
		#LOG.debug(fname) {"key='#{key}', argums='#{argums}' ret=#{ret}"}
		ret
	end

end