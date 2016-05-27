require 'tempfile'

#--
# Copyright (c) 2008-2009, John Mettraux, jmettraux@gmail.com
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# Made in Japan.
#++
#
# Process definitions are tracked via this record class.
#
class Definition < ActiveRecord::Base
	include Models::SylrplmCommon
	#rails2include LinksMixin

	attr_accessible :name, :description, :uri, :launch_fields,  :domain

	#has_many :group_definitions, :dependent => :delete_all
	#has_many :groups, :through => :group_definitions
	#has_many :role_definitions, :dependent => :delete_all
	#has_many :roles, :through => :role_definitions
	has_and_belongs_to_many :roles, :join_table=>:definitions_roles
	#
	# validations
	validates_presence_of :name, :uri
	#
	validates_uniqueness_of :name
	SEP_NAME = '-'

	def name_
		unless tree.nil?
			tree[1]['name'] || tree[1].find { |k, v| v.nil? }.first
		end
	end

	def revision
		fname= "#{self.class.name}.#{__method__}"
		begin
		unless tree.nil?
			tree[1]['revision']
		end
		rescue Exception =>e
			LOG.error(fname) {"Error=#{e}"}
		end
	end

	def tree
		fname= "#{self.class.name}.#{__method__}"
		#LOG.debug(fname) {"definition.id=#{id}"}
		ret=nil
		unless uri.blank?
			begin
				ret=Ruote::Reader.read(uri)
			rescue Exception=>e
				LOG.error(fname) {"Error=#{e}"}
				LOG.debug(fname) {"id=#{id} uri=#{uri}"}
			end
		end
		ret
	end

	def tree_json
		Rufus::Json.encode(tree)
	end

	# Makes sure the 'definition' column contains a string that is Ruby code.
	#
	def rubyize!
		self.definition = Ruote::Reader.to_ruby(tree).strip
	end

	def validate
		super
		validate_uri
	end

	def validate_uri
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug(fname) {"uri=#{uri}"}
		if uri.blank?
			self.errors.add(:base,"nothing to do !!!")
		else
			@_tree = (RuotePlugin.ruote_engine.get_def_parser.parse(uri) rescue nil)
			unless @_tree
				self.errors.add(:base,"uri seems not to contain a process definition!!!")
			end
		end
	end

	def name_translate
		PlmServices.translate("definition_#{name}")
	end

	#
	# Fetching the process description
	#
	def before_save
		self.description ||= OpenWFE::ExpressionTree.get_description(@_tree)
	end

	def ident; name; end

	#
	# get the definition existing for a process name on an object of plmtype and type
	# the search is made for following values:
	# 1- process_name.plmtype.typesobject.value1.value2
	# 2- process_name.plmtype.typesobject.value1
	# 3- process_name.plmtype.typesobject..value2
	# 4- process_name.plmtype.value1.value2
	# 5- process_name.plmtype.value1
	# 6- process_name.plmtype..value2
	# 7- process_name.plmtype.typesobject
	# 8- process_name.plmtype
	# 9- process_name
	#
	def self.get_by_process_name(process_name, a_object, value1, value2)
		fname= "#{self.class.name}.#{__method__}"
		ret = nil
		unless a_object.nil? || process_name.blank?
			plmtype=a_object.modelname
			objtype=a_object.typesobject.name
			unless (value1.nil? || value2.nil?)
				# 1- process_name.plmtype.typesobject.value1.value2
				name = "#{process_name}#{SEP_NAME}#{plmtype}#{SEP_NAME}#{objtype}#{SEP_NAME}#{value1}#{SEP_NAME}#{value2}"
				ret = find_by_name(name)
				LOG.debug(fname) {"1-name=#{name} ret=#{ret}"}
			end
			if ret.nil?
				# 2- process_name.plmtype.typesobject.value1
				unless value1.nil?
					name = "#{process_name}#{SEP_NAME}#{plmtype}#{SEP_NAME}#{objtype}#{SEP_NAME}#{value1}"
					ret = find_by_name(name)
				end
				LOG.debug(fname) {"2-name=#{name} ret=#{ret}"}
			end
			if ret.nil?
				unless value2.nil?
					# 3- process_name.plmtype.typesobject..value2
					name = "#{process_name}#{SEP_NAME}#{plmtype}#{SEP_NAME}#{objtype}#{SEP_NAME}#{SEP_NAME}#{value2}"
					ret = find_by_name(name)
				end
				LOG.debug(fname) {"3-name=#{name} ret=#{ret}"}
			end
			if ret.nil?
				unless (value1.nil? || value2.nil?)
					# 4- process_name.plmtype.value1.value2
					name = "#{process_name}#{SEP_NAME}#{plmtype}#{SEP_NAME}#{value1}#{SEP_NAME}#{value2}"
					ret = find_by_name(name)
					LOG.debug(fname) {"4-name=#{name} ret=#{ret}"}
				end
			end
			if ret.nil?
				# 5- process_name.plmtype.value1
				unless value1.nil?
					name = "#{process_name}#{SEP_NAME}#{plmtype}#{SEP_NAME}#{value1}"
					ret = find_by_name(name)
				end
				LOG.debug(fname) {"5-name=#{name} ret=#{ret}"}
			end
			if ret.nil?
				unless value2.nil?
					# 6- process_name.plmtype..value2
					name = "#{process_name}#{SEP_NAME}#{plmtype}#{SEP_NAME}#{SEP_NAME}#{value2}"
					ret = find_by_name(name)
				end
				LOG.debug(fname) {"6-name=#{name} ret=#{ret}"}
			end
			if ret.nil?
				# 7- process_name.plmtype.typesobject
				name = "#{process_name}#{SEP_NAME}#{plmtype}#{SEP_NAME}#{objtype}"
				ret=find_by_name(name)
				LOG.debug(fname) {"7-name=#{name} ret=#{ret}"}
			end
			if ret.nil?
				# 8- process_name.plmtype
				name = "#{process_name}#{SEP_NAME}#{plmtype}"
				ret=find_by_name(name)
				LOG.debug(fname) {"8-name=#{name} ret=#{ret}"}
			end
			if ret.nil?
				# 9- process_name
				name = "#{process_name}"
				ret=find_by_name(name)
				LOG.debug(fname) {"9-name=#{name} ret=#{ret}"}
			end
		end
		ret
	end

	#
	# Finds all the definitions the user has the right to see
	#
	def self.find_all_for (user)
		alls = all
		unless user.nil?
			user.is_admin? ? alls : alls.select { |d| ! d.is_special? }
		else
		[]
		end
	end

	#
	# Returns true if the definition is special (ie it represents the right
	# to launch an embedded or an untracked definition)
	#
	def is_special?
		['*embedded*', '*untracked*'].include?(self.name)
	end

	#
	# The URI for web links
	#
	def full_uri_obsolete
		return nil unless self.uri
		self.uri.index('/') ? self.uri : "/definitions/#{self.uri}"
	end

	#
	# The URI for launching
	#
	def local_uri_obsolete
		return nil unless self.uri
		u = full_uri
		u[0, 1] == '/' ? "#{config.root}/public#{u}" : u
	end

	#
	# The URI for launching
	# we write the file in the tmp directory because engine.launch method read it
	#
	def local_uri
		fname= "#{self.class.name}.#{__method__}"
		return nil unless self.uri
		#
		tmp_file = Tempfile.new("#{self.name}")
		begin
			tmp_file.write(self.uri)
		ensure
		tmp_file.close
		#tmp_file.unlink   # deletes the temp file
		end
		ret=tmp_file.path
		#ret="#{tmp_file.path}.def"
		#File.open(ret, 'w') do |f|
		#	f.write(self.uri)
		#	f.close
		#end
		#tmp_file.write(self.uri)
		#LOG.debug(fname) {"local_uri=#{ret}"}
		ret
	end

	def usable?
		!uri.blank?
	end

	#
	# Returns the initial workitem payload at launch time (launchitem)
	#
	def launch_fields_hash
		unless launch_fields.blank?
			ret= ActiveSupport::JSON.decode(launch_fields)
		else
			ret={}
		#ret['attribut']  = 'valeur'
		end
		#puts "definition.launch_fields_hash:"+ret.inspect
		ret
	end

	def definition
		''
	end

	def definition_obsolete= (s)
		#    puts "definition.definition("+s.inspect+")"
		return if s.blank?
		pref = "#{config.root}/public"
		base = "/definitions/#{OpenWFE.ensure_for_filename(self.name)}"
		i = ''
		fn = pref + base + i.to_s + '.def'

		# while File.exist?(fn)
		#   i = (i == '') ? 1 : i + 1
		#   fn = pref + base + i.to_s + '.def'
		# end

		File.open(fn, 'w') { |f| f.write(s) }

		self.uri = base + i.to_s + '.def'
	end

	protected

	def links (opts={})
		linkgen = LinkGenerator.new(opts[:request])
		[
			linkgen.hlink('via', 'definitions'),
			linkgen.hlink('self', 'definitions', self.id.to_s)
		]
	end
end

