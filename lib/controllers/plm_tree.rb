require "controllers/plm_modeling"
require "controllers/plm_tree_items"

############################################

############################################
# construction des arbres descendants
# building the descending tree
############################################
#
# build the tree, main method called by controller
#
def  build_tree(obj, view_id, variant_mdlid = nil, level_max = 9999)
	fname="plm_tree.#{self.class.name}.#{__method__}"
	LOG.debug(fname) {">>>>variant_mdlid=#{variant_mdlid}, level_max=#{level_max}"}
	label = t(:ctrl_object_explorer, :typeobj => t("ctrl_#{obj.modelname}"), :ident => obj.label)
	tree = Tree.new({:js_name=>"tree_down", :label => label, :open => true })
	view=View.find(view_id) unless  view_id.nil?
	relations = View.find(view_id).relations unless view.nil?
	unless relations.nil?
		LOG.debug(fname) {"view=#{view}"}
	else
		LOG.debug(fname){"Toutes les relations sont a afficher"}
	end
	if variant_mdlid.nil?
		variant = nil
	else
		variant = PlmServices.get_object_by_mdlid(variant_mdlid)
	end
	unless variant.nil?
	var_effectivities = variant.variant_effectivities
	else
	var_effectivities = []
	end
	LOG.debug(fname) {"variant=#{variant}  level_max=#{level_max}"}
	str_eff=""
	var_effectivities.each do |eff|
		str_eff+="#{eff}\n"
	end
	LOG.debug(fname) {"var_effectivities=\n#{str_eff}"}
	follow_tree(obj, tree, obj, relations, var_effectivities, 0, level_max)
	###TODO a mettre en option group_tree(tree, 0)
	LOG.debug(fname) {"tree size=#{tree.size}"}
	##LOG.debug(fname) {"tree =#{tree.inspect}"}
	session[:tree_object] = obj
	LOG.debug(fname) {"<<<<session[:tree_object]=#{session[:tree_object]}"}
	tree
end

#

#------------------------------------------------------
# associated users
#------------------------------------------------------
def associate_users(node, father)
	usersnode = tree_level("'users_#{father.id}'", t("label_#{father.modelname}_users"), icone_plmtype("user"), icone_plmtype("user"))
	tree_users(usersnode, father)
	node << usersnode if usersnode.size > 0
	if(father.respond_to?(:childs))
		organode = tree_level("'#{father.modelname}_#{father.id}'", t("label_#{father.modelname}_#{father.controller_name}"), icone_plmtype(father.modelname), icone_plmtype(father.modelname))
		tree_organization(organode, father)
	node << organode if organode.size > 0
	end
#if(father.is_a?(Group))
#	groupsnode = tree_level("'groups_#{father.id}'", t("label_#{father.modelname}_groups"), icone_plmtype("group"), icone_plmtype("group"))
#	tree_groups(groupsnode, father)
#	node << groupsnode if groupsnode.size > 0
#end
#LOG.debug(fname) {"usersnode.size=#{usersnode.size}"}
end

# descending path of the tree , recursive method

def function_name(level,method)
	str_level="".rjust(level*2,".")
	fname="#{str_level}plm_tree.#{method}"
end

# descente de l'arbre

# @param root: root object (part ...)
# @param node: current node
# @param father: object father of the node
# @param relations: relations array to take into account
# @param var_effectivities: effectivities of the variant : [#<Part id: 22 ... , #<Part id: 25 ...]
#                           tableau des effectivites de la variante:[#<Part id: 22 ... , #<Part id: 25 ...]
# @param level: current level of the tree
# @return the node after adding other node(s)
#
def follow_tree(root, node, father, relations, var_effectivities, level, level_max)
	fname=function_name(level, __method__)
	LOG.debug(fname) {">>>>>>tree or node=#{node.size} , father=#{father}, level=#{level}"}
	return if level >= level_max
	return if father.nil?
	return if root.nil?
	return if node.nil?
	associate_users(node, father)
	# LOG.info(fname) {"SYLRPLM::TREE_GROUP=#{SYLRPLM::TREE_GROUP}"}
	tree_group=PlmServices.get_property(:TREE_GROUP)
	PlmServices.get_property(:TREE_ORDER).each do |mdl_child|
		add_model(root, node, father, relations, var_effectivities, level, level_max,mdl_child)
	end
	#------------------------------------------------------
	# objects created on this project context
	#------------------------------------------------------
	if father.modelname == "project"
		projownersnode = tree_level("'prj_#{father.id}'", t(:label_projowners))
		tree_projowners(projownersnode,  root, father)
	node << projownersnode if projownersnode.size > 0
	end
	LOG.debug(fname) {"<<<<node.size=#{node.size}"}
	node
end

def add_model(root, node, father, relations, var_effectivities, level, level_max,mdl_child)
	fname=function_name(level, __method__)
	tree_group=PlmServices.get_property(:TREE_GROUP)
	#LOG.debug(fname) {"debut de type #{mdl_child} tree_group=#{tree_group}"}
	if tree_group=="true"
		snode = tree_level("'grp_#{father.id}_#{mdl_child}'", t("label_#{father.modelname}_#{mdl_child}"), icone_plmtype(mdl_child), icone_plmtype(mdl_child), nil, true)
	node<<snode
	end
	links = Link.find_childs(father,  mdl_child)
	LOG.debug(fname) {"type #{mdl_child} , #{links.length} links a tester"}
	links.each do |link|
		add_link(root, node, snode, father, relations, var_effectivities, level, level_max,mdl_child, link)
	end
	unless snode.nil?
		LOG.debug(fname) {"remove snode.size=#{snode.size}"}
	node.remove(snode) if snode.size == 0
	end
#LOG.debug(fname) {"fin de type  #{mdl_child} node.size=#{node.size}"}
end

def add_link(root, node, snode, father, relations, var_effectivities, level,  level_max,mdl_child, link)
	fname=function_name(level, __method__)
	#LOG.debug(fname) {"mdl_child=#{mdl_child} debut link: #{link.child_plmtype} #{link.ident}"}
	#
	# on teste si une des effectivites du lien est comprise dans la variante en cours
	#
	link_effectivities = link.effectivities
	str_eff=""
	link_effectivities.each do |eff|
	#LOG.debug(fname) {"effectivity=#{eff.inspect}"}
		str_eff+="#{eff}\n"
	end
	#LOG.debug(fname) {"effectivities=\n#{str_eff}"}
	unless link_effectivities.nil?
		if link_effectivities.size == 0
			link_effectivities=nil
		end
	end
	#
	if link_effectivities.nil?
		LOG.debug(fname){"link=#{link.ident}, pas d'effectivites sur le lien => on affiche"}
	link_to_show = true
	else
		if var_effectivities.count==0
			link_to_show = true
			LOG.debug(fname){"pas d'effectivites de variante => on affiche"}
		else
			link_to_show = true
			link_effectivities.each do |link_eff|
				if var_effectivities.include?(link_eff)
					LOG.debug(fname){"effectivite=#{link_eff} requise pour variante "}
				else
					link_to_show = false
					LOG.debug(fname){"effectivite=#{link_eff} non requise pour variante "}
				end
			end
		end
	end
	if(link_to_show == true)
		child = PlmServices.get_object(link.child_plmtype, link.child_id)
		# edit du lien
		relation = Relation.find(link.relation_id)
		#LOG.debug(fname){"relation=#{relation}"}
		# pas de relations demandees => toutes
		if relations.nil? || relations.count==0
		show_relation=true
		else
		show_relation = relations.include?(relation)
		end
		msg="show_relation:#{relation.id}.#{relation.ident}, type=#{relation.typesobject.ident} link=#{link.ident}"
		if show_relation
			LOG.info(fname){msg}
			#
			# add node for child
			#
			thenode = add_child(root,father,link, child,level)
			unless relation.stop_tree?
				follow_tree(root, thenode, child, relations, var_effectivities, level+=1, level_max)
			else
				LOG.debug(fname) {"#{PlmServices.get_property(:TREE_RELATION_STOP)} =>stop tree"}
			end
			#taille du noeud
			thenode.label+="(#{thenode.size})" if thenode.size>0
			unless snode.nil?
				snode << thenode
				LOG.debug(fname) {"snode << cnode=#{snode.size}"}
			else
				node << thenode
				LOG.debug(fname) {"node << cnode=#{node.size}"}
			#LOG.debug(fname) {"ajout node.size=#{node.size}"}
			end
		else
		# on parcours la branche sans afficher ce noeud
			if(1==0)
				LOG.info(fname){"no "+msg}
				unless snode.nil?
				thenode=snode
				else
				thenode=node
				end
				follow_tree(root,thenode, child, relations, var_effectivities, level+=1, level_max)
				node<<thenode
				LOG.debug(fname){"node << thenode=#{thenode.size}"}
			end
		end
	# end show_relation
	else
	# on n'affiche pas cette branche
		LOG.info(fname){"branche non affichee: link=#{link.ident}"}
	end
#LOG.debug(fname) {"fin de link: node.size=#{node.size}"}
end

def add_child(root, father, link, child, level)
	fname=function_name(level, __method__)
	#
	# edit du lien
	#
	edit_link_url = url_for(:controller => 'links',
              :action => "edit_in_tree",
              :id => link.id,
              :object_model => father.modelname,
              :object_id => father.id,
              :root_model => root.modelname,
              :root_id => root.id)
	# gsub pour eviter une erreur fatale sur le tree: on ne le voit pas !!!
	rel_name="relation_#{link.relation.name}"
	tr_rel_name=t(rel_name).gsub!("'"," ")
	##quelquefois on perd la traduction !!!!
	tr_rel_name="#{link.relation.name}" if tr_rel_name.blank?
	link_values = link.type_values.gsub('\\','').gsub('"','') unless link.type_values.nil?
	img_rel="<img class=\"icone\" src=\"#{icone_fic(link)}\" title=\"#{clean_text_for_tree(link.tooltip)}\" />"
	if current_user.can_edit?
		edit_link_a = "<a href=\"#{edit_link_url}\" title=\"#{ link_values}\">#{img_rel}#{tr_rel_name}</a>"
	else
		edit_link_a="........................."
	end
	unless child.nil?
		show_url={:controller => child.controller_name,
			:action => 'show',
			:id => "#{child.id}"}
		ctrl_name="ctrl_#{child.modelname}"
		show_a="<a href=\"#{url_for(show_url)}\" title=\"#{child.tooltip}\">#{child.label}</a>"
		#
		# destroy du lien
		#
		if child.frozen?
			remove_link_a = ""
		else
			remove_link_url = url_for(:controller => 'links',
              :action => "remove_link",
              :id => link.id,
              :object_model => father.modelname,
              :object_id => father.id)
			remove_link_a = "<a href=\"#{remove_link_url}\">#{img_cut}</a>"
		end
		options={
			:id => link.id ,
			:label  => "#{edit_link_a} | #{show_a} | #{remove_link_a}",
			:icon => icone_fic(child),
			:icon_open => icone_fic(child),
			:title => clean_text_for_tree("#{link.tooltip}"),
			:url => url_for(edit_link_url),
			:open => false,
			:obj_child => child,
			:link => link
		}
		html_options = {
			:alt => child.ident_plm
		}
	else
	# child no more existing
		options={
			:id => link.id ,
			:label  => "#{edit_link_a} | #{t(:child_no_more_existing)} | #{remove_link_a}",
			#:icon => icone_fic(child),
			#:icon_open => icone_fic(child),
			:title => clean_text_for_tree("#{link.tooltip}"),
			:url => url_for(edit_link_url),
			:open => false,
			#:obj_child => child,
			:link => link}
	end
	cnode = Node.new(options,html_options)
end

# construction des arbres montants

# building ascending tree
############################################
#
# build the ascending tree, main method called by controller
#
def build_tree_up(obj, view_id)
	fname="plm_tree."#{self.class.name}.#{__method__}"
	LOG.debug(fname) {"build_tree_up:obj=#{obj.inspect}"}
	lab=t(:ctrl_object_referencer, :typeobj => t("ctrl_#{obj.modelname}"), :ident => obj.label)
	tree = Tree.new({:js_name=>"tree_up", :label => lab ,:open => true})
	relations = View.find(view_id).relations unless  view_id.nil?
	add_owners(tree, obj)
	PlmServices.get_property(:TREE_ORDER).each do |mdl_child|
		follow_father(mdl_child, tree, obj, relations)
		session[:tree_object_up] = obj
	end
	tree
end

def add_owners (tree, obj)
	fname="plm_tree."#{self.class.name}.#{__method__}"
	#
	# owner project at the creation
	#
	LOG.debug(fname) {"obj.owner=#{obj.owner.inspect}"}
	add_owner(tree, obj.owner)
	add_owner(tree, obj.group)
	if(obj.respond_to? :projowner)
		add_owner(tree, obj.projowner)
	end
	tree
end

def add_owner(tree, father)
	unless father.nil?
		url = {:controller => get_controller_from_model_type(father.modelname), :action => 'show', :id => "#{father.id}"}
		ctrl_name="ctrl_#{father.modelname}"
		img_rel="<img class=\"icone\" src=\"#{icone_fic(father)}\" title=\"#{father.tooltip}\" />"
		options={
			:id => father.id ,
			:label => "#{img_rel} | #{father.label}",
			:icon => icone_fic(father),
			:icon_open => icone_fic(father),
			:title => clean_text_for_tree(father.tooltip),
			:url => url_for(url),
			:open => true
		}
		html_options = {
			:alt => "alt:"+father.ident
		}
		cnode = Node.new(options,html_options)
	tree<<cnode
	end
end

#

# ascending path of the tree , recursive method
# only one level
# @param modelname: model name of the father of the node (part/project/customer ...)
# @param node: current node
# @param obj: object child of the node
# @param relations: relations array to take into account
# @return the node after adding other node(s)
#
def follow_father(modelname, node, obj, relations)
	model=eval modelname.capitalize
	##links=Link.find_fathers(get_modelname(obj), obj,  modelname)
	links=Link.find_fathers(obj,  modelname)
	links.each do |link|
		begin
			father = model.find(link.father_id)
			fname="plm_tree:"#{self.class.name}.#{__method__}"
			LOG.debug(fname) {" father=#{father.ident}"}
			url = {:controller => get_controller_from_model_type(modelname), :action => 'show', :id => "#{father.id}"}
			relation = Relation.find(link.relation_id)
			ctrl_name="ctrl_#{father.modelname}"
			img_rel="<img class=\"icone\" src=\"#{icone_fic(link)}\" title=\"#{link.tooltip}\" />"
			options={
				:id => link.id ,
				:label => "#{img_rel}#{link.relation.name} | #{father.label}",
				:icon => icone_fic(father),
				:icon_open => icone_fic(father),
				:title => clean_text_for_tree(father.tooltip),
				:url => url_for(url),
				:open => false
			}
			html_options = {
				:alt => "alt:"+father.ident
			}
		rescue Exception=>e
			options={
				:id => link.id ,
				:label => "#{img_rel}#{link.relation.name} | Father not found",
				#:icon => icone_fic(father),
				#:icon_open => icone_fic(father),
				:title => "Father not found for link #{link}, relation=#{link.relation}",
				#:url => url_for(url),
				:open => false
			}
			html_options = {}
		end
		cnode = Node.new(options, html_options)
		node << cnode
	end
	node
end

