# frozen_string_literal: true

############################################
# construction des arbres descendants
############################################
def build_tree_actions_by_roles(actions_by_roles)
  fname = 'plm_tree:' # {self.class.name}.#{__method__}"
  LOG.debug(fname) { 'begin' }
  lab = t(:ctrl_actions_by_roles)
  tree = Tree.new(js_name: 'tree_down', label: lab, open: true)
  id = 0
  actions_by_roles.each_key do |role|
    LOG.debug(fname) { "role=#{role}" }
    # #role = Role.find_by_title(srole)
    id += 1
    options = {
      id: id,
      label: role.to_s,
      icon: icone(role),
      icon_open: icone(role),
      title: clean_text_for_tree(role.tooltip.to_s),
      url: url_for(role_path(role)),
      open: true,
      obj_child: role
    }
    role_node = Node.new(options)
    tree << role_node
    actions_by_roles[role].each do |controller|
      next if controller[1].nil?
      next unless controller[1].count > 0
      id += 1
      help_controller = 'help_' + controller[0].chomp('Controller').downcase!
      options = {
        id: id,
        label: (controller[0]).to_s,
        # http://0.0.0.0:3000/help?help=help_parts
        url: url_for('/help?help=' + help_controller),
        open: false
      }
      ctrl_node = Node.new(options)
      role_node << ctrl_node
      controller[1].sort.each do |action|
        id += 1
        help_action = help_controller + '_' + action
        options = {
          id: id,
          label: action.to_s,
          url: url_for('/help?help=' + help_action),
          open: false
        }
        action_node = Node.new(options)
        ctrl_node << action_node
        # puts "controller=#{controller[0]} , #{controller[1].count} actions=#{controller[1]}"
      end
    end
  end
  LOG.debug(fname) { "tree size=#{tree.size}" }
  tree
end
