class Favori
  attr_reader :items
  def initialize
    @items={}
  end

  def add(obj)
    #puts "favori.add:"+obj.object_type
    unless @items[obj.object_type].nil?
      current_item=@items[obj.object_type].find { |item| item.id==obj.id }
    else
      @items[obj.object_type]=[]
    end
    if(not current_item)
      @items[obj.object_type] << obj
    end
    #puts "favori.add:"+@items.inspect
  end

  def reset(type=nil)
    unless type.nil?
      @items[type]=nil
      #puts "favori.reset:"+@items[type].inspect
    else
      @items.size==0
    end

  end

  def get(type)
    #puts "favori.get:"+@items[type].inspect
    unless @items[type].nil?
      @items[type]
    else
      []
    end
  end
end
