class FavoriProject
  attr_reader :items
  def initialize
      @items=[]   
  end
  
  def add_project(project)
     current_item=@items.find { |item| item.id==project.id }
     if(not current_item) 
       @items << project
     end
   end
   def empty
    @items.size==0
  end
end
