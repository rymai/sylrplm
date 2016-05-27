class Favori
	include Controllers::PlmObjectControllerModule
	attr_reader :items
	def initialize
		@items={}
	end
	@@PLM_TYPE_AS_FAVORI=["customer","document","part","project","user"]

	def self.can_favori?(modelname)
		@@PLM_TYPE_AS_FAVORI.include?(modelname)
	end

	def add(obj)
		#puts "favori.add:"+obj.modelname
		unless @items[obj.modelname].nil?
			current_item=@items[obj.modelname].find { |item| item.id==obj.id }
		else
		@items[obj.modelname]=[]
		end
		if(not current_item)
		@items[obj.modelname] << obj
		end
	#puts "favori.add:"+@items.inspect
	end

	def remove(obj)
		puts "favori.remove:"+obj.modelname+":"+@items[obj.modelname].inspect
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
		#puts "favori.count_object"
		nbr = 0
		@items.each do |type, favoris|
			#puts "favori.count_object:#{type}=#{favoris.count}"
			nbr += favoris.count unless favoris.nil?
		end
		nbr
	end

	def get(type)
		#puts "favori.get:"+@items[type].inspect
		unless @items[type].nil?
		@items[type]
		else
		[]
		end
	end

end
