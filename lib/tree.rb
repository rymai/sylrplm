# frozen_string_literal: true

require 'node'

class Tree < Node
  attr_reader :id, :parent, :buffer_nodes

  def initialize(options = {}, html_options = {}, &block)
    super
    @tree_nodes = []
    @buffer_nodes = ''
    @id = 0
    @parent = -1
  end

  def make(node, level)
    i = 0
    level += 1
    if level < 50
      while i <= (node.size - 1)
        unless node.empty?
          node.nodes[i].parent = node.id
          n = node.nodes[i]
          append(n)
          make(node.nodes[i], level)
        end
        i += 1
      end
    else
      raise Exception, 'Too many levels, certainly because of loop in links'
  end
  end

  def put_all(*nodes)
    nodes.each do |n|
      self << n
    end
  end

  def to_s
    fname = "Tree:#{__method__}"
    LOG.debug(fname) { '>>>>>>' }
    append(self)
    level = 0
    begin
       @nodes.each do |tn|
         tn.parent = 0
         append(tn)
         make(tn, level)
         LOG.debug(fname) { '<<<<<<' }
       end
       # syl "<script>\nd = new dTree('d');\n#{@buffer_nodes}document.write(d);\n</script>"
       ret = "<script>\n#{@options[:js_name]} = new dTree('#{@options[:js_name]}');\n#{@buffer_nodes}document.write(#{@options[:js_name]});\n</script>".html_safe
     rescue Exception => e
       LOG.error(fname) { "EXCEPTION during nodes print: #{e} " }
       ret = "EXCEPTION during nodes print: #{e}"
     end
    ret
  end

  def append(n)
    @buffer_nodes += "#{@options[:js_name]}.add(#{n.id},#{n.parent},'#{n.label}',\"#{n.url}\",'#{n.event_name}','#{n.title}','#{n.target}','#{n.icon}','#{n.icon_open}',#{n.open});\n"
  end

  def self.for(path)
    require 'pathname'
    t = Tree.new(label: File.basename(path))
    make_path(t, Pathname.new(path))
    t
  end

  def self.make_path(pn, path)
    if path.directory?
      path.children.sort.each do |c|
        n = Node.new(label: File.basename(c).to_s)
        pn << n
        make_path(n, c)
      end
    end
  end

  # syl
  attr_writer :nodes
end
