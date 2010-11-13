require 'node'


class Tree < Node 
    
  attr_reader :id, :parent,:buffer_nodes

  def initialize(options={},html_options={},&block) 
    super
    @tree_nodes=[]
    @buffer_nodes=""
    @id,@parent=0,-1
    
  end
   
  def make(node)
    i=0

    while  i <= (node.size-1) 
      if node.size  >0 
        node.nodes[i].parent=node.id
        n = node.nodes[i]
        append(n)
        make(node.nodes[i])
      end 
      i+=1;
    end

  end 
  def put_all(*nodes)
    nodes.each do |n|
      self << n
    end 
  end

  def to_s

    append(self)
    @nodes.each do |tn|
      tn.parent=0    
      append(tn)
      make(tn)   
    end
       
    "<script>\nd = new dTree('d');\n#{@buffer_nodes}document.write(d);\n</script>"
  end

   
  def append(n)
    @buffer_nodes+="d.add(#{n.id},#{n.parent},'#{n.label}',\"#{n.url}\",'#{n.event_name}','#{n.title}','#{n.target}','#{n.icon}','#{n.icon_open}',#{n.open});\n"
  end
  
  def Tree.for(path)
    require 'pathname'
    t=Tree.new(:label => File.basename(path))
    make_path(t,Pathname.new(path))   
      
    t
  end
   
  def Tree.make_path(pn,path)
    if path.directory? 
      path.children.sort.each do |c|
        n=Node.new(:label => File.basename(c).to_s)
        pn << n
        make_path(n,c)                 
      end 
    end

  end
  
  
   
end