class FavoriDocumentItem
  attr_reader :document
  def initialize(document)
      @document=document
  end
  def title
      @document.title    
  end
end