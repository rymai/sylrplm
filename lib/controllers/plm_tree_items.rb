require "controllers/plm_modeling"

#------------------------------------------------------

# objects created on a project context
#------------------------------------------------------
def tree_projowners(node,  child, father)
	if father.model_name == "project"
		fname="#{self.class.name}.#{__method__}"
		LOG.debug (fname){"father=#{father} "}
		tree_objects(node, Customer.find_all_by_projowner_id(father.id))
		tree_objects(node, Part.find_all_by_projowner_id(father.id))
		tree_objects(node, Document.find_all_by_projowner_id(father.id))
	end
	node
end

#

# add objects nodes on a node
# @param node: the node to update
# @param objs: objects array to
def tree_objects(node, objs)
	fname="#{self.class.name}.#{__method__}"
	LOG.debug (fname){"tree_objects=#{objs} "}
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

#

# create a node corresponding to an object
# @param obj: the object to associate to the node
# @return the node corresponding to the object
#
def tree_object(obj)
	url={:controller => obj.controller_name, :action => :show, :id => "#{obj.id}"}
	options={
		:id => "'#{obj.model_name}_#{obj.ident_plm}'",
		:label => t("ctrl_"+obj.model_name)+':'+obj.ident_plm ,
		:icon=>icone_fic(obj),
		:icon_open=>icone_fic(obj),
		:title => obj.designation,
		:open => false,
		:url=>url_for(url)
	}
	cnode = Node.new(options,nil)
end

#

#
# utilisateurs associes a l'objet
# complete a node with users nodes associated to an object
# @param node: current node
# @father: the object associated to user(s)
# @return the completed node
#
def tree_users(node, father)
	fname="plm_tree:#{controller_class_name}.#{__method__}"
	if father.respond_to? :users
		#LOG.debug (fname){"#{father.ident} father.users=#{father.users}"}
		unless father.users.nil?
			begin
				father.users.each do |child|
				#LOG.debug (fname){"child=#{child.inspect}"}
					url = {:controller => 'users', :action => 'show', :id => child.id}
					options = {
						:id => "#{child.id}" ,
						:label => child.ident_plm ,
						:icon  => icone_fic(child),
						:icon_open => icone_fic(child),
						:title => child.tooltip,
						:open => false,
						:url  => url_for(url)
					}
					#LOG.debug (fname){"user:#{child.ident}"}
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

#

# roles ou groupes associes a l'objet
# complete a node with roles or groups nodes associated to an object
# @param node: current node
# @father: the object associated to roles or groups
# @return the completed node
#
def tree_organization(node, father)
	fname="plm_tree:#{controller_class_name}.#{__method__}"
	#LOG.debug (fname){"#{father.ident} father.childs=#{father.childs}"}
	unless father.childs.nil?
		begin
			father.childs.each do |child|
				url = {:controller => child.controller_name, :action => 'show', :id => child.id}
				options = {
					:id => "#{child.id}" ,
					:label => child.ident_plm ,
					:icon  => icone_fic(child),
					:icon_open => icone_fic(child),
					:title => child.tooltip,
					:open => false,
					:url  => url_for(url)
				}
				#LOG.debug (fname){"child#{child.ident}"}
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

#

# groupes associes a l'objet
# complete a node with groups nodes associated to an object
# @param node: current node
# @father: the object associated to groups
# @return the completed node
#
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
						:icon  => icone_fic(child),
						:icon_open => icone_fic(child),
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
# utilitaires des arbres
# useful methodes for tree building
############################################

#
# cree un noeud intermediaire pour definir un niveau de regroupement d'objets de meme nature par exemple
# create an intermediate node in order to group some similar objects
# @param id : node id
# @param title : the label of the node
# @param icon : the icon
# @param icon_open : the open icon
# @param designation
# @param open : open (true) or closed (false) at start
# @return the intermediate node
#
def tree_level(id, title, icon = nil, icon_open = nil, designation = nil, open = false)
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

#

# suppress some caracteres not compatible with html
# transform some caracteres to html tag
#
def clean_text_for_tree(txt)
	txt.gsub!('\n\n','\n')
	txt.gsub!('\n','<br/>')
	txt.gsub!(10.chr,'<br/>')
	txt.gsub!('\t','')
	txt.gsub!("'"," ")
	txt.gsub!('"',' ')
	txt
end

#

# create a html tag for image
# @param name: image name
#
def img(name)
	"<img class=\"icone\" src=\"/images/#{name}.png\"/>"
end

#

# specific cut image
#
def img_cut
	img("cut")
end

#

# suppress identical nodes (same id)
# for example, each instance of an object at diffrent position in the tree become only one node with the count
# recursive method
# @param thenode: the node to compute
# @param level: the current level
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

