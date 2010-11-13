class FavoriPartItem
  attr_reader :part
  def initialize(part)
      @part=part
  end
  def title
      @part.title    
  end
end