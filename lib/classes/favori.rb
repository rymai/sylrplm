class Favori
	include Controllers::PlmObjectControllerModule
	attr_reader :items
	def initialize
		@items={}
	end
	@@PLM_TYPE_AS_FAVORI=["customer","document","part","project","user"]

	def self.can_favori?(model_name)
		@@PLM_TYPE_AS_FAVORI.include?(model_name)
	end

	def add(obj)
		#puts "favori.add:"+obj.model_name
		unless @items[obj.model_name].nil?
			current_item=@items[obj.model_name].find { |item| item.id==obj.id }
		else
		@items[obj.model_name]=[]
		end
		if(not current_item)
		@items[obj.model_name] << obj
		end
	#puts "favori.add:"+@items.inspect
	end

	def remove(obj)
		puts "favori.remove:"+obj.model_name+":"+@items[obj.model_name].inspect
		@items[obj.model_name].delete(obj)
	end

	def reset(type=nil)
		unless type.nil?
			@items[type]=nil
		#puts "favori.reset:"+@items[type].inspect
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
