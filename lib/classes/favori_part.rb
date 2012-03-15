class FavoriPart
  attr_reader :items
  def initialize
    @items=[]   
  end
  
  def add_part(part)
    current_item=@items.find { |item| item.id==part.id }
    if(not current_item) 
      @items << part
    end
  end
  def empty
    @items.size==0
  end
end
