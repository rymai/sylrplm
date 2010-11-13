class FavoriDocument 
  attr_reader :items
  def initialize
      @items=[]   
  end
  def add_document(document)
     current_item=@items.find { |item| item.id==document.id }
     puts "favori_document.add_document:"+document.inspect
     puts "favori_document.add_document:current_item="+current_item.inspect
     if(not current_item) 
     puts "FavoriDocument.add_document:"+document.inspect
       @items << document
     puts "FavoriDocument.add_document:items="+@items.inspect
     end
   end
  def empty
    @items.size==0
  end
  
end
