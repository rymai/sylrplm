class FavoriPart

  attr_reader :items

  def initialize
    @items = []
  end

  def add_part(part)
    current_item = @items.detect { |item| item.id == part.id }
    @items << part unless current_item
  end

  def empty
    @items.empty?
  end

end
