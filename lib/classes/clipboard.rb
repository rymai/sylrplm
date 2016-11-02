class Clipboard
	include Controllers::PlmObjectControllerModule
	attr_reader :items
	def initialize
		@items={}
	end
	@@PLM_TYPE_AS_CLIPBOARD=["customer","document","part","project","user"]

	def self.can_clipboard?(modelname)
		@@PLM_TYPE_AS_CLIPBOARD.include?(modelname)
	end

	def add(obj)
		unless @items[obj.modelname].nil?
			current_item=@items[obj.modelname].find { |item| item.id==obj.id }
		else
		@items[obj.modelname]=[]
		end
		if(not current_item)
		@items[obj.modelname] << obj
		end
	end

	def remove(obj)
		puts "clipboard.remove:"+obj.modelname+":"+@items[obj.modelname].inspect
		@items[obj.modelname].delete(obj)
	end

	def reset(type=nil)
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug(fname) {"type=#{type} nb=#{@items[type].size}"}
		unless type.nil?
			@items[type]=nil
		LOG.debug(fname) {"type=#{type} @items[type]='#{@items[type]}'"}
		else
		@items.size=0
		end

	end

	def count
		nbr = 0
		@items.each do |type, clipboards|
			nbr += clipboards.count unless clipboards.nil?
		end
		nbr
	end

	def get(type)
		unless @items[type].nil?
		@items[type]
		else
		[]
		end
	end

end
