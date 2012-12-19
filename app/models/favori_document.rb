class FavoriDocument

  attr_reader :items

  def initialize
    @items = []
  end

  def add_document(document)
    current_item = @items.detect { |item| item.id == document.id }
    @items << document unless current_item
  end

  def empty
    @items.empty?
  end

end
