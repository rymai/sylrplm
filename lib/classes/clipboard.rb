# frozen_string_literal: true

class Clipboard
  include Controllers::PlmObjectController
  attr_reader :items
  def initialize
    @items = {}
  end
  @@PLM_TYPE_AS_CLIPBOARD = %w[customer document part project user]

  def self.can_clipboard?(modelname)
    @@PLM_TYPE_AS_CLIPBOARD.include?(modelname)
  end

  def add(obj)
    if @items[obj.modelname].nil?
      @items[obj.modelname] = []
    else
      current_item = @items[obj.modelname].find { |item| item.id == obj.id }
    end
    @items[obj.modelname] << obj unless current_item
  end

  def remove(obj)
     @items[obj.modelname].delete(obj)
  end

  def reset(type = nil)
    fname = "#{self.class.name}.#{__method__}"
    LOG.debug(fname) { "type=#{type} nb=#{@items[type].size}" }
    if type.nil?
      @items.size = 0
    else
      @items[type] = nil
      LOG.debug(fname) { "type=#{type} @items[type]='#{@items[type]}'" }
    end
  end

  def count
    nbr = 0
    @items.each do |_type, clipboards|
      nbr += clipboards.count unless clipboards.nil?
    end
    nbr
  end

  def get(type)
    if @items[type].nil?
      []
    else
      @items[type]
    end
  end
end
