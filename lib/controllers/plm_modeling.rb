require "zip/zip"

######################################################

# build a modeling file
######################################################
#
# get the types of datafiles existing on a tree
#
def get_types_datafiles_on_tree(tree)
	fname="plm_tree:#{__method__}"
	#LOG.debug (fname) {"#{tree.nodes.count} nodes"}
	ret = get_types_datafiles_on_node(tree,0)
	ret
end

#

# get the types of datafiles existing on a node
# recursive method
#
def get_types_datafiles_on_node(node, level)
	fname="plm_tree:#{__method__}"
	ret=[]
	lnk = get_node_link(node)
	unless lnk.nil?
		LOG.debug(fname) {"child_plmtype=#{lnk.child_plmtype} lnk=#{lnk.inspect} "}
		child = lnk.child
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
	node.nodes.each do |anode|
		get_types_datafiles_on_node(anode, level+1).each do |type|
			ret << type unless ret.include?(type)
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
	fname="plm_tree:#{controller_class_name}.#{__method__}"
	nodes = tree.nodes
	matrix = nil
	files = []
	ret_filename = "#{plmobject.ident}.#{type_model.name}"
	ret_type = "application/#{type_model.name}"
	LOG.debug(fname) {" type_model=Object type.datafile.scad"}
	ret = ""
	ret << "module #{plmobject.ident}() {#{10.chr}"
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
		content = datafile.read_file_for_tree
		unless content.nil?
			LOG.debug(fname) {"file:#{datafile.file_fullname} : #{content.size}"}
			ret << "//file#{10.chr}"
			ret << "#{content}#{10.chr}"
		else
			datafile.errors.each do |type,err|
				plmobject.errors.add_to_base err
			end
			return nil
		end
	end
	unless ret.nil?
		ret << ""
		ret << "}#{10.chr}"
		ret << "#{plmobject.ident}();#{10.chr}"
	end
	plmobject.errors.add_to_base errors unless errors.blank?
	{"content"=>ret, "filename"=>ret_filename, "content_type"=>ret_type}
end

def read_node(plmobject, node, type_model, ret, mx, files, errors)
	fname="plm_tree:#{controller_class_name}.#{__method__}"
	lnk = get_node_link(node)
	LOG.debug(fname) {"plmobject=#{plmobject} type_model=#{type_model} ret=#{ret} mx=#{mx} files=#{files} node.id=#{node.id} lnk=#{lnk}"}
	unless lnk.nil?
		child = lnk.child
		rb_values = nil
		yamx=false
		if lnk.father_plmtype == plmobject.model_name && lnk.child_plmtype == 'document'
			child.datafiles.each do |datafile|
				if datafile.typesobject.name == type_model.name
					files << datafile unless files.include?(datafile)
					LOG.debug(fname) { "lnk=#{lnk}"}
					#rb_values = decod_json(lnk, lnk.type_values, "", lnk.ident)
					#OpenWFE::Json::from_json(lnk.type_values)
					ret << "//tmx#{10.chr}"
					if mx.nil?
						ret<<"#{datafile.file_name}();"
					else
						ret<<"toto"
					end
					ret << "#{10.chr}"
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
						ret << "rotate([#{mx_rx}, #{mx_ry},#{mx_rz}])#{10.chr}"
					yamx=true
					end
				end
				unless mx_dx.nil?  && mx_dy.nil? && mx_dz.nil?
					unless  mx_dx.zero?  && mx_dy.zero?  && mx_dz.zero?
						ret << "translate([#{mx_dx}, #{mx_dy}, #{mx_dz}])#{10.chr}"
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
		ret << ""
		ret <<"{#{10.chr}" if yamx==true
		node.nodes.each do |nod|
			read_node(plmobject, nod, type_model, ret, mx, files,errors)
		end
		ret << ""
		ret <<"}#{10.chr}" if yamx==true
	end
	ret
end

#

def build_model_tree_old(plmobject, tree, type_model)
	fname="plm_tree:#{controller_class_name}.#{__method__}"
	bloc=""
	bloc << "nodes = tree.nodes\n"
	bloc << "matrix = nil\n"
	bloc << "files = []\n"
	bloc << "ret_filename = \"\#{plmobject.ident}.\#{type_model.name}\"\n"
	bloc << "ret_type = \"application/\#{type_model.name}\"\n"
	bloc << bloc_read_node(type_model)+"\n"
	bloc <<"LOG.debug (fname) {\" type_model=#{type_model}\"}\n"
	bloc << "#{type_model.get_fields_values_type_only_by_key("build_model_tree_begin")}\n"
	bloc << "if nodes.count > 0\n"
	bloc << "		nodes.each do |nod|\n"
	bloc << "			read_node(plmobject, nod, type_model, ret, matrix, files)\n"
	bloc << "		end\n"
	bloc << "else\n"
	bloc << "		plmobject.datafiles.each do |datafile|\n"
	bloc << "			if datafile.typesobject==type_model\n"
	bloc << "        files << datafile unless files.include?(datafile)\n"
	bloc << "			end\n"
	bloc << "		end\n"
	bloc << "end\n"
	bloc << "		puts \"\#{files.count} files\"\n"
	bloc << "files.each do |datafile|\n"
	bloc << "		content = datafile.read_file_for_tree\n"
	bloc << "		unless content.nil?\n"
	bloc << "		puts \">>build_model_tree_file:\#{datafile.file_fullname} : \#{content.size}\"\n"
	bloc << "			#{type_model.get_fields_values_type_only_by_key("build_model_tree_file")}\n"
	bloc << "		puts '<<build_model_tree_file'\n"
	bloc << "		else\n"
	bloc << "			datafile.errors.each do |type,err|\n"
	bloc << "					plmobject.errors.add_to_base err\n"
	bloc << "			end\n"
	bloc << "			return nil\n"
	bloc << "		end\n"
	bloc << "end\n"
	bloc << "#{type_model.get_fields_values_type_only_by_key("build_model_tree_end")}\n"
	bloc << "{\"content\"=>ret, \"filename\"=>ret_filename, \"content_type\"=>ret_type}\n"
	LOG.debug (fname) {"****************** bloc=\n#{bloc}\n**********"}
	ret=eval bloc
	LOG.debug (fname) {"****************** ret=\n#{ret}"}
	ret
end

#

# return content of a node of a tree
# recursive method
#
def bloc_read_node_old(type_model)
	fname="plm_tree:#{controller_class_name}.#{__method__}"
	bloc=""
	bloc << "def read_node(plmobject, node, type_model, ret, mx, files)\n"
	bloc << "  lnk = get_node_link(node)\n"
	bloc << "  child = lnk.child\n"
	bloc << "  rb_values = nil\n"
	bloc << "  yamx=false\n"
	bloc << "  if lnk.father_plmtype == plmobject.model_name && lnk.child_plmtype == 'document'\n"
	#
	# get the model content
	#
	bloc << "    child.datafiles.each do |datafile|\n"
	bloc << "      if datafile.typesobject.name == type_model.name\n"
	##bloc << "puts \"read_node:father=\#{lnk.father} child=\#{child} datafile=\#{datafile}\"\n"
	bloc << "        files << datafile unless files.include?(datafile)\n"
	bloc << "        rb_values = OpenWFE::Json::from_json(lnk.type_values)\n"
	##mx inutilise bloc << "        mx=rb_values[\"matrix\"] unless rb_values.nil?\n"
	bloc << "        #{type_model.get_fields_values_type_only_by_key("build_model_tree_matrix")}\n"
	#scad: ret<<"#{datafile.file_name}();"
	bloc << "      end\n"
	bloc << "    end\n"
	bloc << "  elsif lnk.child_plmtype == 'part'\n"
	#
	# get the structure information
	#
	bloc << "    rb_values = OpenWFE::Json::from_json(lnk.type_values)\n"
	bloc << "    unless rb_values.nil?\n"
	bloc << "      mx_dx = rb_values[\"relation_matrix_dx\"] \n"
	bloc << "      mx_dy = rb_values[\"relation_matrix_dy\"] \n"
	bloc << "      mx_dz = rb_values[\"relation_matrix_dz\"] \n"
	bloc << "      mx_rx = rb_values[\"relation_matrix_rx\"] \n"
	bloc << "      mx_ry = rb_values[\"relation_matrix_ry\"] \n"
	bloc << "      mx_rz = rb_values[\"relation_matrix_rz\"] \n"
	bloc << "    end\n"
	bloc << "    puts \"mx_dx=\#{mx_dx} mx_dy=\#{mx_dy} mx_dz=\#{mx_dz} mx_rx=\#{mx_rx} mx_ry=\#{mx_ry} mx_rz=\#{mx_rz} \""
	bloc << "      unless mx_rx.nil? && mx_rx.zero? && mx_ry.ry && mx_ry.zero? && mx_rz.nil? && mx_rz.zero?\n"
	bloc << "        #{type_model.get_fields_values_type_only_by_key("build_model_tree_rotate")}\n"
	#scad: ret << "rotate([#{mx_rx}, #{mx_ry}, #{mx_rz}])\n"
	bloc << "        yamx=true\n"
	bloc << "      end\n"
	bloc << "      unless mx_dx.nil? && mx_dx.zero? && mx_dy.nil? && mx_dy.zero? && mx_dz.nil? && mx_dz.zero? \n"
	bloc << "        #{type_model.get_fields_values_type_only_by_key("build_model_tree_translate")}\n"
	#scad: ret << "translate([\#{mx_dx, \#{mx_dy}, \#{mx_dz}])\n"
	bloc << "        yamx=true\n"
	bloc << "    end\n"
	bloc << "  end\n"
	build_model_tree_nodes_before=type_model.get_fields_values_type_only_by_key("build_model_tree_nodes_before")
	unless build_model_tree_nodes_before.nil?
		bloc << "        #{build_model_tree_nodes_before} if yamx==true\n"
	#scad: ret << "{"
	end

	bloc << "  node.nodes.each do |nod|\n"
	bloc << "    read_node(plmobject, nod, type_model, ret, mx, files)\n"
	bloc << "  end\n"
	build_model_tree_nodes_after=type_model.get_fields_values_type_only_by_key("build_model_tree_nodes_after")
	unless build_model_tree_nodes_after.nil?
		bloc << "        #{build_model_tree_nodes_after} if yamx==true\n"
	#scad: ret <<"}"
	end
	bloc << "  ret\n"
	bloc << "end\n"
end

#

# return the link associated to a node
#
def get_node_link(node)
	fname="plm_tree:#{__method__}"
	lnk=nil
	begin
		lnk = Link.find(node.id) unless node.id==0
	rescue Exception => e
		LOG.warn (fname) {"node #{node.id} is not a link"}
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

