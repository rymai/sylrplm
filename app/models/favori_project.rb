class FavoriProject

  attr_reader :items

  def initialize
    @items = []
  end

  def add_project(project)
    current_item = @items.detect { |item| item.id == project.id }
    @items << project unless current_item
  end

  def empty
    @items.empty?
  end

end
