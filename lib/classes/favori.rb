class Favori
  include Controllers::PlmObjectControllerModule
  attr_reader :items
  def initialize
    @items={}
  end

  def add(obj)
    #puts "favori.add:"+obj.model_name
    unless @items[obj.model_name].nil?
      current_item=@items[obj.model_name].find { |item| item.id==obj.id }
    else
      @items[obj.model_name]=[]
    end
    if(not current_item)
      @items[obj.model_name] << obj
    end
    #puts "favori.add:"+@items.inspect
  end
  
  def remove(obj)
    @items[obj.model_name].remove(obj)
  end
  
  def reset(type=nil)
    unless type.nil?
      @items[type]=nil
      #puts "favori.reset:"+@items[type].inspect
    else
      @items.size=0
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
