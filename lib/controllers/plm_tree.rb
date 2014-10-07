
require "controllers/plm_modeling"
require "controllers/plm_tree_items"

############################################
# construction des arbres descendants
# building the descending tree
############################################
#
# build the tree, main method called by controller
#
def  build_tree(obj, view_id, variant_mdlid = nil, level_max = 9999)
	fname="plm_tree:#{controller_class_name}.#{__method__}"
	#LOG.debug (fname) {"variant_mdlid=#{variant_mdlid}, level_max=#{level_max}"}
	lab=t(:ctrl_object_explorer, :typeobj => t("ctrl_#{obj.model_name}"), :ident => obj.label)
	tree = Tree.new({:js_name=>"tree_down", :label => lab, :open => true })
	view=View.find(view_id) unless  view_id.nil?
	relations = View.find(view_id).relations unless view.nil?
	unless relations.nil?
		#LOG.debug (fname) {"view=#{view}"}
	else
		#LOG.debug (fname){"Toutes les relations sont a afficher"}
	end
	if variant_mdlid.nil?
		variant = nil
	else
		variant = PlmServices.get_object_by_mdlid(variant_mdlid)
	end
	unless variant.nil?
		var_effectivities = variant.var_effectivities
	else
		var_effectivities = []
	end
	#LOG.debug (fname) {"variant=#{variant}, var_effectivities=#{var_effectivities.inspect} level_max=#{level_max}"}
	follow_tree(obj, tree, obj, relations, var_effectivities, 0, level_max)
	###TODO a mettre en option group_tree(tree, 0)
	#LOG.debug (fname) {"tree size=#{tree.size}"}
	##LOG.debug (fname) {"tree =#{tree.inspect}"}
	tree
end

#
# descending path of the tree , recursive method
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
			#LOG.debug (fname) {"link_effectivities=#{link_effectivities}"} unless link_effectivities.nil?
			unless link_effectivities.nil?
				if link_effectivities.size == 0
					link_effectivities=nil
				end
			end
			#
			if link_effectivities.nil? #|| link_effectivities.count==0
				#LOG.debug (fname){"link=#{link.ident}, pas d'effectivites sur le lien => on affiche"}
			link_to_show = true
			else
				#LOG.debug (fname){"link=#{link.ident}, link_effectivities=#{link_effectivities}"}
				if var_effectivities.count==0
					link_to_show = true
					#LOG.debug (fname){"pas d'effectivites de variante => on affiche"}
				else
					link_to_show = true
					link_effectivities.each do |link_eff|
						unless var_effectivities.include?(link_eff)
							#LOG.debug (fname){"link=#{link.ident}"}
							#LOG.debug (fname){"effectivite #{link_eff}"}
							#LOG.debug (fname){"requise pour variante : #{var_effectivities.include?(link_eff)}"}
						link_to_show = false
						end
					end
				end
			end
			if(link_to_show == true)
				#LOG.info (fname){"branche affichee: link=#{link.ident}"}
				child = PlmServices.get_object(link.child_plmtype, link.child_id)
				# edit du lien
				relation = Relation.find(link.relation_id)
				#LOG.debug (fname){"relation=#{relation.id}.#{relation.ident}"}
				# pas de relations demandees => toutes
				if relations.nil? || relations.count==0
				show_relation=true
				else
				show_relation = relations.include?(relation)
				end
				if show_relation
					#LOG.info (fname){"show_relation:#{relation.id}.#{relation.ident}, type=#{relation.typesobject.ident}"}
					img_rel="<img class=\"icone\" src=\"#{icone_fic(link)}\" title=\"#{clean_text_for_tree(link.tooltip)}\" />"
					#unless relation.typesobject.fields.nil?
					link_values = link.type_values.gsub('\\','').gsub('"','') unless link.type_values.nil?
					edit_link_url = url_for(:controller => 'links',
              :action => "edit_in_tree",
              :id => link.id,
              :object_model => father.model_name,
              :object_id => father.id,
              :root_model => root.model_name,
              :root_id => root.id)
              # gsub pour eviter une erreur fatale sur le tree: on ne le voit pas !!!
              		rel_name="relation_#{link.relation.name}"
              		tr_rel_name=t(rel_name)
              		#########.gsub!("'"," ") on perd la traduction !!!!
              		LOG.info (fname){"rel_name=relation_#{link.relation.name} : #{tr_rel_name} "}
					edit_link_a = "<a href=#{edit_link_url} title=\"#{link_values}\">#{img_rel}#{tr_rel_name}</a>"
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
						:icon => icone_fic(child),
						:icon_open => icone_fic(child),
						:title => clean_text_for_tree("#{link.tooltip}"),
						:url => url_for(edit_link_url),
						:open => false,
						:obj_child => child,
						:link => link
					}
					html_options = {
						:alt => "alt:"+child.ident_plm
					}

						#LOG.debug (fname){"options=#{options.inspect}"}
						cnode = Node.new(options)
						#LOG.debug (fname){"level=#{level} root=#{root} father=#{father} child=#{child} "}
						unless relation.stop_tree?
							follow_tree(root, cnode, child, relations, var_effectivities, level+=1, level_max)
						end
						#taille du noeud
						cnode.label+="(#{cnode.size})" if cnode.size>0
						unless snode.nil?
						snode << cnode
						else
						node << cnode

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
				#LOG.info (fname){"branche non affichee: link=#{link.ident}"}
			end
		end
		unless snode.nil?
			#LOG.debug (fname) {"snode.size=#{snode.size}"}
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



############################################
# construction des arbres montants
# building ascending tree
############################################
#
# build the ascending tree, main method called by controller
#
def build_tree_up(obj, view_id)
	lab=t(:ctrl_object_referencer, :typeobj => t("ctrl_#{obj.model_name}"), :ident => obj.label)
	tree = Tree.new({:js_name=>"tree_up", :label => lab ,:open => true})
	relations = View.find(view_id).relations unless  view_id.nil?
	PlmServices.get_property(:TREE_ORDER).each do |mdl_child|
		follow_father(mdl_child, tree, obj, relations)
		session[:tree_object_up] = obj
	end
	tree
end

#
# ascending path of the tree , recursive method
# only one level
# @param model_name: model name of the father of the node (part/project/customer ...)
# @param node: current node
# @param obj: object child of the node
# @param relations: relations array to take into account
# @return the node after adding other node(s)
#
def follow_father(model_name, node, obj, relations)
	model=eval model_name.capitalize
	links=Link.find_fathers(get_model_name(obj), obj,  model_name)
	links.each do |link|
		father = model.find(link.father_id)
		url = {:controller => get_controller_from_model_type(model_name), :action => 'show', :id => "#{father.id}"}
		relation = Relation.find(link.relation_id)
		ctrl_name="ctrl_#{father.model_name}"
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
		cnode = Node.new(options, html_options)
		node << cnode
	end
	node
end



