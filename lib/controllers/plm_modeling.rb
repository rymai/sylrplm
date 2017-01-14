######################################################

# build a modeling file
######################################################
#
# get the types of datafiles existing on a tree
#
def get_types_datafiles_on_tree(tree)
	fname="plm_modeling:#{__method__}"
	ret=[]
	unless tree.nil?
		#LOG.debug(fname) {"#{tree.nodes.count} nodes"}
		ret = get_types_datafiles_on_node(tree,0)
	end
	ret
end

#

# get the types of datafiles existing on a node
# recursive method
#
def get_types_datafiles_on_node(node, level)
	fname="plm_modeling:#{__method__}"
	ret=[]
	unless node.nil?
		lnk = get_node_link(node)
		unless lnk.nil?
			child = lnk.child
			LOG.debug(fname) {"child_plmtype=#{lnk.child_plmtype} lnk=#{lnk.inspect} child=#{child} "}
			unless child.nil?
				if lnk.child_plmtype == 'document'
					LOG.debug(fname) {"child=#{child} #{child.datafiles.count} datafiles"}
					child.datafiles.each do |datafile|
						LOG.debug(fname) {"doc.datafile.typesobject=#{datafile.typesobject} "}
						ret << datafile.typesobject unless ret.include?(datafile.typesobject)
					end
				end
				if  lnk.child_plmtype == 'part'
					docs=child.documents
					docs.each do |doc|
						doc.datafiles.each do |datafile|
							LOG.debug(fname) {"part.doc.datafile.typesobject=#{datafile.typesobject} "}
							ret << datafile.typesobject unless ret.include?(datafile.typesobject)
						end
					end
				end
			end
		end
		node.nodes.each do |anode|
			get_types_datafiles_on_node(anode, level+1).each do |type|
				ret << type unless ret.include?(type)
			end
		end
	end
	ret
end

#

# main method to get the whole content of a model of a plm object
# called by the controller method for the structure tab: ctrl_show_design
# call the recursive method read_node
# result depends of the datatype (scad,...)
# @param customer or document or part or project
#
def build_model_tree(plmobject, tree, type_model)
	fname="plm_modeling:"#{self.class.name}.#{__method__}"
	nodes = tree.nodes
	matrix = nil
	files = []
	ret_filename = "#{plmobject.ident}.#{type_model.name}"
	ret_type = "application/#{type_model.name}"
	LOG.debug(fname) {" type_model=Object type.datafile.scad"}
	if type_model=="scad"
		ret = ""
		ret << "module #{plmobject.ident}() {#{10.chr}"
	else
	# init du zip
		stringio=::StringIO.new
		ret=Zip::OutputStream::new(stringio,true)
	end
	errors=[]
	if nodes.count > 0
		nodes.each do |nod|
			ret=read_node(plmobject, nod, type_model, ret, matrix, files, errors)
		end
	else
		plmobject.datafiles.each do |datafile|
			if datafile.typesobject==type_model
			files << datafile unless files.include?(datafile)
			end
		end
	end
	LOG.debug(fname) {"#{files.count} files ret=#{ret}"}
	files.each do |datafile|
		LOG.debug(fname) {"datafile=#{datafile}"}
		content = datafile.read_file_for_tree
		unless content.nil?
			LOG.debug(fname) {"datafile.file_fullname=#{datafile.file_fullname} : #{content.size}"}
			if type_model=="scad"
				ret << "//file#{10.chr}"
				ret << "#{content}#{10.chr}"
			else
			ret.put_next_entry(datafile.file_fullname)
			ret<< content
			end
		else
			LOG.debug(fname) {"datafile.errors= : #{datafile.errors}"}
			datafile.errors.each do |type,err|
				plmobject.errors.add :base ,  err
			end
			ret=nil
		end
	end
	unless ret.nil?
		if type_model=="scad"
			ret << ""
			ret << "}#{10.chr}"
			ret << "#{plmobject.ident}();#{10.chr}"
		else
		# fin du zip
		ret.close_buffer
		stringio.rewind
		ret = stringio.sysread
		end
	end
	plmobject.errors.add(:base ,  errors) unless errors.blank?
	{"content"=>ret, "filename"=>ret_filename, "content_type"=>ret_type}
end

def read_node(plmobject, node, type_model, ret, mx, files, errors)
	fname="plm_modeling:"#{self.class.name}.#{__method__}"
	lnk = get_node_link(node)
	LOG.debug(fname) {"plmobject=#{plmobject} type_model=#{type_model} ret=#{ret} mx=#{mx} files=#{files} node.id=#{node.id} lnk=#{lnk}"}
	unless lnk.nil?
		child = lnk.child
		rb_values = nil
		yamx=false
		if lnk.father_plmtype == plmobject.modelname && lnk.child_plmtype == 'document'
			child.datafiles.each do |datafile|
				if datafile.typesobject.name == type_model.name
					files << datafile unless files.include?(datafile)
					LOG.debug(fname) { "lnk=#{lnk}"}
					if type_model=="scad"
						ret << "//tmx#{10.chr}"
						if mx.nil?
							ret<<"#{datafile.file_name}();"
						else
							ret<<"toto"
						end
						ret << "#{10.chr}"
					else
					end
				end
			end
		elsif lnk.child_plmtype == 'part'
			LOG.debug(fname) { "lnk=#{lnk}"}
			rb_values = lnk.decod_json(lnk.type_values, "", lnk.ident)
			LOG.debug(fname) { "rb_values=#{rb_values}"}
			unless rb_values.nil?
				mx_dx = rb_values["relation_matrix_dx"].to_f
				mx_dy = rb_values["relation_matrix_dy"].to_f
				mx_dz = rb_values["relation_matrix_dz"].to_f
				mx_rx = rb_values["relation_matrix_rx"].to_f
				mx_ry = rb_values["relation_matrix_ry"].to_f
				mx_rz = rb_values["relation_matrix_rz"].to_f
				LOG.debug(fname) { "mx_dx=#{mx_dx} mx_dy=#{mx_dy} mx_dz=#{mx_dz} mx_rx=#{mx_rx} mx_ry=#{mx_ry} mx_rz=#{mx_rz}"}
				unless mx_rx.nil? && mx_ry.nil? && mx_rz.nil?
					unless mx_rx.zero? && mx_ry.zero? && mx_rz.zero?
						if type_model=="scad"
							ret << "rotate([#{mx_rx}, #{mx_ry},#{mx_rz}])#{10.chr}"
						end
					yamx=true
					end
				end
				unless mx_dx.nil?  && mx_dy.nil? && mx_dz.nil?
					unless  mx_dx.zero?  && mx_dy.zero?  && mx_dz.zero?
						if type_model=="scad"
							ret << "translate([#{mx_dx}, #{mx_dy}, #{mx_dz}])#{10.chr}"
						end
					yamx=true
					end
				end
			else
				LOG.error(fname) {"Error decoding fields:#{lnk.errors.full_messages}"}
				errors<<lnk.errors
				ret=nil
			end
		end
	end
	unless ret.nil?
		if type_model=="scad"
			ret << ""
			ret <<"{#{10.chr}" if yamx==true
			node.nodes.each do |nod|
				read_node(plmobject, nod, type_model, ret, mx, files,errors)
			end
			ret << ""
			ret <<"}#{10.chr}" if yamx==true
		end
	end
	ret
end

# return the link associated to a node
#
def get_node_link(node)
	fname="plm_modeling:#{__method__}"
	lnk=nil
	unless node.nil?
		begin
			lnk = Link.find(node.id) unless node.id==0
		rescue Exception => e
			LOG.warn(fname) {"node #{node.id} is not a link"}
		end
	end
	lnk
end

#
#  useful methods called by custo blocs in typesobjects
#
=begin
def mx_rx(matrix)
matrix["RX"]
end
def mx_ry(matrix)
matrix["RY"]
end
def mx_rz(matrix)
matrix["RZ"]
end
def mx_tx(matrix)
matrix["DX"]
end
def mx_ty(matrix)
matrix["DY"]
end
def mx_tz(matrix)
matrix["DZ"]
end
=end

