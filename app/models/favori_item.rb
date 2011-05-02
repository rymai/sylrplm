class FavoriItem
  attr_reader :object
  def initialize(obj)
    @object=obj
  end
  def title
    @object.title    
  end
end