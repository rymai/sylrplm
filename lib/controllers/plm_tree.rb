def build_model_datafile(obj, datatype)
	fname="plm_tree:#{controller_class_name}.#{__method__}"
	LOG.debug (fname) {"obj=#{obj}"}
	if(datatype=="scad")
	ret="#{obj.read_file} \n"
	ret << "#{obj.filename.split(".")[0]}();\n"
	end
	ret
end
           
def build_model(obj, tree, datatype)
	fname="plm_tree:#{controller_class_name}.#{__method__}"
	LOG.debug (fname) {"obj=#{obj.inspect}"}
	ret="module #{obj.ident}() {\n"
	nodes = tree.nodes
	mx=nil
	files=[]
	nodes.each do |nod|
		read_node(nod, datatype, ret, mx, files)
	end
	files.each do |datafile|
		LOG.debug (fname) {"datafile=#{datafile.inspect}"}
		ret<<"#{datafile.read_file} \n"
	end
	ret << "}\n"
	ret << "#{obj.ident}();\n"
end

def build_model_file_obsolete(obj, tree, datatype)
	file = File.open("#{Rails.root}/public/tmp/#{obj.ident}.scad", "w+")
	file.write("module #{obj.ident}() {\n")
	nodes = tree.nodes
	mx=nil
	files=[]
	nodes.each do |nod|
		read_node(nod, datatype, file, mx, files)
	end
	files.each do |datafile|
		file.write("#{datafile.read_file} \n")
	end
	file.write("}\n")
	file.write("#{obj.ident}();\n")
	file.close
	file
end

def read_node(node, datatype, content, mx, files)
	fname="plm_tree:#{controller_class_name}.#{__method__}"
	lnk = Link.find(node.id)
	child = PlmServices.get_object(lnk.child_plmtype, lnk.child_id)
	LOG.debug (fname) {"lnk.child_plmtype=#{lnk.child_plmtype}"}
	rb_values = nil
	if lnk.child_plmtype == "document"
		child.datafiles.each do |datafile|
			LOG.debug (fname) {"datafile=#{datafile.inspect} datafile.typesobject.name=#{datafile.typesobject.name}"}
			if datafile.typesobject.name == datatype
				files << datafile unless files.include?(datafile)
				rb_values = OpenWFE::Json::from_json(lnk.values)
				mx=rb_values["matrix"] unless rb_values.nil?
				LOG.debug (fname) {"write(#{datafile.ident} filename=#{datafile.filename} mx=#{mx}"}
				if mx.nil?
				content<<"\t#{datafile.filename.split(".")[0]}();\n"
				else
					content<<"\trotate([#{mx["RX"]}, #{mx["RY"]}, #{mx["RZ"]}])" unless mx["RX"].zero? && mx["RY"].zero? && mx["RZ"].zero? 	
				  content<<"\ttranslate([#{mx["DX"]}, #{mx["DY"]}, #{mx["DZ"]}])" unless mx["DX"].zero? && mx["DY"].zero? && mx["DZ"].zero? 
				  content<<"#{datafile.filename.split(".")[0]}();\n" 
				end
			end
		end
	elsif lnk.child_plmtype == "part"
		rb_values = OpenWFE::Json::from_json(lnk.values)
		mx = rb_values["matrix"] unless rb_values.nil?
		yamx=false
		unless mx.nil?
			
			unless mx["RX"].zero? && mx["RY"].zero? && mx["RZ"].zero? 
				content<<"\trotate([#{mx["RX"]}, #{mx["RY"]}, #{mx["RZ"]}])" 
				yamx=true	
			end
			unless mx["DX"].zero? && mx["DY"].zero? && mx["DZ"].zero? 
				content<<"\ttranslate([#{mx["DX"]}, #{mx["DY"]}, #{mx["DZ"]}])" 
				yamx=true
			end
			content <<"{" if yamx==true
		end
		nodes = node.nodes
		nodes.each do |nod|
			read_node(nod, datatype, content, mx, files)
		end
		content <<"}" if yamx==true
	end
end



def read_node_file(node, datatype, file, mx, files)
	fname="plm_tree:#{controller_class_name}.#{__method__}"
	lnk = Link.find(node.id)
	child = PlmServices.get_object(lnk.child_plmtype, lnk.child_id)
	LOG.debug (fname) {"lnk.child_plmtype=#{lnk.child_plmtype}"}
	rb_values = nil
	if lnk.child_plmtype == "document"
		child.datafiles.each do |datafile|
			LOG.debug (fname) {"datafile.typesobject.name=#{datafile.typesobject.name}"}
			if datafile.typesobject.name == datatype
				files << datafile unless files.include?(datafile)
				mx=rb_values["matrix"] unless rb_values.nil?
				LOG.debug (fname) {"write(#{datafile.ident} filename=#{datafile.filename} mx=#{mx}"}
				if mx.nil?
				file.write("\t#{datafile.filename.split(".")[0]}();\n") 
				else
				
				file.write("\ttranslate([#{mx["DX"]}, #{mx["DY"]}, #{mx["DZ"]}]) #{datafile.filename.split(".")[0]}();\n") 
				end
			end
		end
	elsif lnk.child_plmtype == "part"
		rb_values = OpenWFE::Json::from_json(lnk.values)
		mx = rb_values["matrix"] unless rb_values.nil?
		nodes = node.nodes
		nodes.each do |nod|
			read_node(nod, datatype, file, mx, files)
		end
	end
end

############################################
# construction des arbres descendants
############################################
def  build_tree(obj, view_id, variant_id = nil, level_max = 9999)
	fname="plm_tree:#{controller_class_name}.#{__method__}"
	LOG.debug (fname) {"variant_id=#{variant_id}, level_max=#{level_max}"}
	lab=t(:ctrl_object_explorer, :typeobj => t("ctrl_"+obj.model_name), :ident => obj.label)
	tree = Tree.new({:js_name=>"tree_down", :label => lab, :open => true })
	view=View.find(view_id) unless  view_id.nil?
	relations = View.find(view_id).relations unless view.nil?
	unless relations.nil?
		LOG.debug (fname) {"view=#{view}"}
	else
		LOG.debug (fname){"Toutes les relations sont a afficher"}
	end
	unless variant_id.nil?
		variant=PlmServices.get_object("part",variant_id)
	var_effectivities = variant.var_effectivities
	else
	var_effectivities = []
	end
	LOG.debug (fname) {"variant=#{variant}, var_effectivities=#{var_effectivities.inspect} level_max=#{level_max}"}
	follow_tree(obj, tree, obj, relations, var_effectivities, 0, level_max)
	###TODO a mettre en option group_tree(tree, 0)
	LOG.debug (fname) {"tree size=#{tree.size}"}
	tree
end

# descente de l'arbre (recursif)

# root,
# node,
# father,
# relations,
# var_effectivities: tableau des effectivites de la variante:[#<Part id: 22 ... , #<Part id: 25 ...]
# level
#
def follow_tree(root, node, father, relations, var_effectivities, level, level_max)
	fname="plm_tree:#{controller_class_name}.#{__method__}"
	return if level >= level_max
	#
	# LOG.info (fname) {"tree or node=#{node} , father=#{father.ident}, relations=#{relations}"}
	#------------------------------------------------------
	# associated users: begin
	#------------------------------------------------------
	usersnode = tree_level("'users_#{father.id}'", t("label_#{father.model_name}_users"), icone_plmtype("user"), icone_plmtype("user"))
	tree_users(usersnode, father)
	node << usersnode if usersnode.size > 0
	if(father.respond_to?(:childs))
		organode = tree_level("'#{father.model_name}_#{father.id}'", t("label_#{father.model_name}_#{father.controller_name}"), icone_plmtype(father.model_name), icone_plmtype(father.model_name))
		tree_organization(organode, father)
		node << organode if organode.size > 0
	end
	#if(father.is_a?(Group))
	#	groupsnode = tree_level("'groups_#{father.id}'", t("label_#{father.model_name}_groups"), icone_plmtype("group"), icone_plmtype("group"))
	#	tree_groups(groupsnode, father)
	#	node << groupsnode if groupsnode.size > 0
	#end
	
	#LOG.debug (fname) {"usersnode.size=#{usersnode.size}"}
	#------------------------------------------------------
	# associated users: end
	#------------------------------------------------------
	# LOG.info (fname) {"SYLRPLM::TREE_GROUP=#{SYLRPLM::TREE_GROUP}"}
	PlmServices.get_property(:TREE_ORDER).each do |mdl_child|
		if PlmServices.get_property(:TREE_GROUP)
			snode = tree_level("'grp_#{father.id}'", t("label_#{father.model_name}_#{mdl_child}"), icone_plmtype(mdl_child), icone_plmtype(mdl_child))
		else
			snode = nil
		end
		links = Link.find_childs(father,  mdl_child)
		#LOG.debug (fname) {"links(#{mdl_child})=#{links.inspect}"}
		links.each do |link|

		#
		# on teste si une des effectivites du lien est comprise dans la variante en cours
		#
			link_effectivities = link.effectivities
			#LOG.debug (fname) {"link=#{link.inspect}"}
			LOG.debug (fname) {"link_effectivities=#{link.effectivities.inspect}"} unless link.effectivities.nil?
			unless link_effectivities.nil?
				if link_effectivities.count==0
					link_effectivities=nil
				end
			end
			#
			if link_effectivities.nil? #|| link_effectivities.count==0
				LOG.debug (fname){"link=#{link.ident}, pas d'effectivites sur le lien => on affiche"}
			link_to_show = true
			else
				LOG.debug (fname){"link=#{link.ident}, link_effectivities=#{link_effectivities}"}
				if var_effectivities.count==0
					link_to_show = true
					LOG.debug (fname){"pas d'effectivites de variante => on affiche"}
				else
					link_to_show = true
					link_effectivities.each do |link_eff|
						unless var_effectivities.include?(link_eff)
							LOG.debug (fname){"link=#{link.ident}:effectivite #{link_eff} requise pour variante : #{var_effectivities.include?(link_eff)}"}
						link_to_show = false
						end
					end
				end
			end
			if(link_to_show == true)
				LOG.info (fname){"branche affichee: link=#{link.ident}"}
				child = PlmServices.get_object(link.child_plmtype, link.child_id)
				# edit du lien
				relation = Relation.find(link.relation_id)
				LOG.debug (fname){"relation=#{relation.id}.#{relation.ident}"}
				# pas de relations demandees => toutes
				if relations.nil? || relations.count==0
				show_relation=true
				else
				show_relation = relations.include?(relation)
				end
				if show_relation
					LOG.info (fname){"show_relation:#{relation.id}.#{relation.ident}, type=#{relation.typesobject.ident}"}
					img_rel="<img class=\"icone\" src=\"#{icone(link)}\" title=\"#{clean_text_for_tree(link.tooltip)}\" />"
					#unless relation.typesobject.fields.nil?
					link_values = link.values.gsub('\\','').gsub('"','') unless link.values.nil?
					edit_link_url = url_for(:controller => 'links',
              :action => "edit_in_tree",
              :id => link.id,
              :object_model => father.model_name,
              :object_id => father.id,
              :root_model => root.model_name,
              :root_id => root.id)
					edit_link_a = "<a href=#{edit_link_url} title=\"#{link_values}\">#{img_rel}#{link.relation.name}</a>"
					#LOG.debug (fname){"edit_link_a=#{edit_link_a}"}
					# destroy du lien
					if child.frozen?
						remove_link_a = ""
					else
						remove_link_url = url_for(:controller => 'links',
              :action => "remove_link",
              :id => link.id,
              :object_model => father.model_name,
              :object_id => father.id)
						remove_link_a = "<a href=\"#{remove_link_url}\">#{img_cut}</a>"
					end
					# show child
					show_url={:controller => child.controller_name,
						:action => 'show',
						:id => "#{child.id}"}
					ctrl_name="ctrl_#{child.model_name}"
					show_a="<a href=\"#{url_for(show_url)}\" title=\"#{child.tooltip}\">#{child.label}</a>"
					options={
						:id => link.id ,
						:label  => "#{edit_link_a} | #{show_a} | #{remove_link_a}",
						:icon => icone(child),
						:icon_open => icone(child),
						:title => clean_text_for_tree("#{link.tooltip}"),
						:url => url_for(edit_link_url),
						:open => false,
						:obj_child => child,
						:link => link
					}
					html_options = {
						:alt => "alt:"+child.ident_plm
					}
					unless relation.stop_tree?
						LOG.debug (fname){"options=#{options.inspect}"}
						cnode = Node.new(options)
						LOG.debug (fname){"level=#{level} root=#{root} father=#{father} child=#{child} "}
						follow_tree(root, cnode, child, relations, var_effectivities, level+=1, level_max)
						#taille du noeud
						cnode.label+="(#{cnode.size})" if cnode.size>0
						unless snode.nil?
						snode << cnode
						else
						node << cnode
					end
					end
				else
				# on parcours la branche sans afficher ce noeud
					LOG.info (fname){"no show_relation:#{relation.id}.#{relation.ident}, type=#{relation.typesobject.ident}"}
					unless snode.nil?
					thenode=snode
					else
					thenode=node
					end
					follow_tree(root, thenode, child, relations, var_effectivities, level+=1, level_max)
				end
			else
			# on n'affiche pas cette branche
				LOG.info (fname){"branche non affichee: link=#{link.ident}"}
			end
		end
		unless snode.nil?
			LOG.debug (fname) {"snode.size=#{snode.size}"}
		node << snode if snode.size > 0
		end
	end
	#------------------------------------------------------
	# objects created on this project context
	#------------------------------------------------------
	if father.model_name == "project"
		projownersnode = tree_level("'prj_#{father.id}'", t(:label_projowners))
		tree_projowners(projownersnode,  father)
	node << projownersnode if projownersnode.size > 0
	end
	node
end

#------------------------------------------------------

# objects created on a project context
#------------------------------------------------------
def tree_projowners(node,  father)
	if father.model_name == "project"
		tree_objects(node, Customer.find_by_projowner_id(father.id))
		tree_objects(node, Part.find_by_projowner_id(father.id))
		tree_objects(node, Document.find_by_projowner_id(father.id))
	end
	node
end

def tree_objects(node, objs)
	if objs.is_a?(Array)
		objs.each do |obj|
			pnode=tree_object(obj)
			node<<pnode
		end
	else
		unless objs.nil?
			pnode=tree_object(objs)
		node<<pnode
		end
	end
	node
end

def tree_object(obj)
	url={:controller => obj.controller_name, :action => :show, :id => "#{obj.id}"}
	options={
		:id => "'#{obj.model_name}_#{obj.ident_plm}'",
		:label => t("ctrl_"+obj.model_name)+':'+obj.ident_plm ,
		:icon=>icone(obj),
		:icon_open=>icone(obj),
		:title => obj.designation,
		:open => false,
		:url=>url_for(url)
	}
	cnode = Node.new(options,nil)
end

#

#------------------------------------------------------
# utilisateurs associes a l'objet
#------------------------------------------------------
def tree_users(node, father)
	fname="plm_tree:#{controller_class_name}.#{__method__}"
	if father.respond_to? :users
		LOG.debug (fname){"#{father.ident} father.users=#{father.users}"}
		unless father.users.nil?
			begin
				father.users.each do |child|
					LOG.debug (fname){"child=#{child.inspect}"}
					url = {:controller => 'users', :action => 'show', :id => child.id}
					options = {
						:id => "#{child.id}" ,
						:label => child.ident_plm ,
						:icon  => icone(child),
						:icon_open => icone(child),
						:title => child.tooltip,
						:open => false,
						:url  => url_for(url)
					}
					LOG.debug (fname){"user:#{child.ident}"}
					cnode = Node.new(options, nil)
					node << cnode
				end
			rescue Exception => e
				LOG.warn (__method__.to_s){"Exception=#{e}"}
			end
		end
	end
	node
end

#------------------------------------------------------
# roles ou groupes associes a l'objet
#------------------------------------------------------
def tree_organization(node, father)
	fname="plm_tree:#{controller_class_name}.#{__method__}"
		LOG.debug (fname){"#{father.ident} father.childs=#{father.childs}"}
		unless father.childs.nil?
			begin
				father.childs.each do |child|
					url = {:controller => child.controller_name, :action => 'show', :id => child.id}
					options = {
						:id => "#{child.id}" ,
						:label => child.ident_plm ,
						:icon  => icone(child),
						:icon_open => icone(child),
						:title => child.tooltip,
						:open => false,
						:url  => url_for(url)
					}
					LOG.debug (fname){"child#{child.ident}"}
					cnode = Node.new(options, nil)
					node << cnode
					tree_organization(cnode, child)
				end
			rescue Exception => e
				LOG.warn (fname){e}
			end
		end
	#LOG.debug (fname){"node=#{node.inspect}"}
	node
end
#------------------------------------------------------
# groupes associes a l'objet
#------------------------------------------------------
def tree_groups(node, father)
	fname="plm_tree:#{controller_class_name}.#{__method__}"
	if father.respond_to? :groups
		LOG.debug (fname){"#{father.ident} father.groups=#{father.groups}"}
		unless father.groups.nil?
			begin
				father.groups.each do |child|
					url = {:controller => 'groups', :action => 'show', :id => child.id}
					options = {
						:id => "#{child.id}" ,
						:label => child.ident_plm ,
						:icon  => icone(child),
						:icon_open => icone(child),
						:title => child.tooltip,
						:open => false,
						:url  => url_for(url)
					}
					LOG.debug (fname){"group:#{child.ident}"}
					cnode = Node.new(options, nil)
					node << cnode
				end
			rescue Exception => e
				LOG.warn (fname){e}
			end
		end
	end
	LOG.debug (fname){"node=#{node.inspect}"}
	node
end

############################################
# construction des arbres montants
############################################

def build_tree_up(obj, view_id)
	lab=t(:ctrl_object_referencer, :typeobj => t("ctrl_"+obj.model_name), :ident => obj.label)
	tree = Tree.new({:js_name=>"tree_up", :label => lab ,:open => true})
	relations = View.find(view_id).relations unless  view_id.nil?
	PlmServices.get_property(:TREE_ORDER).each do |mdl_child|
		follow_father(mdl_child, tree, obj, relations)
		session[:tree_object_up] = obj
	end
	tree
end

def follow_father(model_name, node, obj, relations)
	model=eval model_name.capitalize
	links=Link.find_fathers(get_model_name(obj), obj,  model_name)
	links.each do |link|
		father = model.find(link.father_id)
		url = {:controller => get_controller_from_model_type(model_name), :action => 'show', :id => "#{father.id}"}
		relation = Relation.find(link.relation_id)
		ctrl_name="ctrl_#{father.model_name}"
		img_rel="<img class=\"icone\" src=\"#{icone(link)}\" title=\"#{link.tooltip}\" />"
		options={
			:id => link.id ,
			:label => "#{img_rel}#{link.relation.name} | #{father.label}",
			:icon => icone(father),
			:icon_open => icone(father),
			:title => clean_text_for_tree(father.tooltip),
			:url => url_for(url),
			:open => false
		}
		html_options = {
			:alt => "alt:"+father.ident
		}
		cnode = Node.new(options, html_options)
		node << cnode
	end
	node
end

############################################
# utilitaires des arbres
############################################

#
# cree un noeud intermediaire pour definir un niveau de regroupement d'objets de meme nature par exemple
#
def   tree_level(id, title, icon = nil, icon_open = nil, designation = nil, open = false)
	fname="plm_tree:#{controller_class_name}.#{__method__}"
	options={
		:id => id,
		:label => title,
		:icon => icon,
		:icon_open => icon_open,
		:title => designation,
		:open => open
	}
	cnode = Node.new(options,nil)
end

def clean_text_for_tree(txt)
	txt.gsub!('\n\n','\n')
	txt.gsub!('\n','<br/>')
	txt.gsub!(10.chr,'<br/>')
	txt.gsub!('\t','')
	txt.gsub!("'"," ")
	txt.gsub!('"',' ')
	txt
end

def img(name)
	"<img class=\"icone\" src=\"/images/#{name}.png\"/>"
end

def img_cut
	img("cut")
end

def group_tree(thenode, level)
	# elimination des doublons avec comptage
	fname="plm_tree:#{controller_class_name}.#{__method__}"
	cur_quantity = thenode.nodes.count
	tab=" "*(level+1)
	LOG.info (fname){"#{tab} begin ************ #{cur_quantity} noeuds devient #{thenode.nodes.count} "}
	begin
	# on sauve le tableau des fils
		old_nodes = thenode.nodes
		# on vide les fils
		thenode.nodes = []
		# parcours des fils
		old_nodes.each do |node|
		###LOG.debug (fname) {"#{tab}node=#{node.id}:#{node.obj_child.ident}:#{node.quantity}"}
		# on ajoute la 1ere occurence de ce noeud
			if node.quantity.nil?
			node.quantity = 1
			thenode << node
			end
			# on cumule les noeuds identiques a celui ci
			old_nodes.each do |other_node|
			# pas celui en cours
				unless other_node == node
					# egalite des objets fils des 2 noeuds
					if other_node.equals?(node)
					node.quantity += 1
					other_node.quantity = 0
					end
				end
			end
			# fin de ce fils, on maj son label avec la quantite
			node.label="#{node.label} *#{node.quantity}"
			group_tree(node, level+=1)
		end
	rescue Exception => e
		LOG.debug (fname){"#{tab}error:#{e}"}
	end
	LOG.info (fname){"#{tab} end ************ #{cur_quantity} noeuds devient #{thenode.nodes.count} "}
	thenode
end

############################################
# fin des arbres
############################################

