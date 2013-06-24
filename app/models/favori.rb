# require 'controllers/plm_object_controller_module'

class Favori
  # include ::Controllers::PlmObjectControllerModule

  attr_reader :items

  def initialize
    @items = {}
  end

  def add(obj)
    current_item = nil
    if @items[obj.model_name].nil?
      @items[obj.model_name] = []
    else
      current_item = @items[obj.model_name].find { |item| item.id == obj.id }
    end

    @items[obj.model_name] << obj unless current_item
  end

  def remove(obj)
    @items[obj.model_name].remove(obj)
  end

  def reset(type = nil)
    if type.nil?
      @items.size = 0
    else
      @items[type] = nil
    end
  end

  def get(type)
    @items[type].nil? ? [] : @items[type]
  end
end
