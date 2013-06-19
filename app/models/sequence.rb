class Sequence < ActiveRecord::Base
	include Models::SylrplmCommon
	validates_presence_of :utility, :value
	validates_uniqueness_of :utility
	#
	
	def ident
		"#{self.utility}.#{self.value}.mod:#{self.modify}.seq:#{self.sequence}"	
	end
	
	def self.get_next_seq(utility)
		current=find_for(utility)
		ret=nil
		unless current.nil?
			old=current.value
			ret=current.value.next
			current.update_attribute("value",ret)
		end
		ret
	end

	def self.get_previous_seq(utility)
		current=find_for(utility)
		ret=nil
		unless current.nil?
			old=current.value
			ret=current.value.prev # n existe pas !!
			current.update_attribute("value",ret)
		end
		ret
	end

	def self.get_constants
		Module.constants.select do |constant_name|
			constant = eval constant_name
			isClass=constant.is_a? Class
			puts 'Sequence.get_constants='+constant.to_s+' class='+isClass.to_s
		#if not constant.nil? && isClass && constant.extend? ActiveRecord::Base

		end
	end

	def self.find_all
		find(:all, :order=>"utility")
	end

	def self.find_for(utility)
		find(:first, :order=>"utility", :conditions => ["utility = '#{utility}' "])
	end

	# recherche des attributs d'un modele
	def self.find_cols_for(model)
		ret=[]
		find_all.each do |line|
			tokens=line.split(".")[0]
			if(tokens[0]==model)
			ret<<tokens[1]
			end
		end
		ret
	end

	# recherche d'un attribut d'un modele
	def self.find_col_for(model,col)
		ret=nil
		find_all.each do |line|
			tokens=line.utility.split(".")
			#puts "Sequence.find_col_for:#{model}.#{col}:#{tokens.inspect}"
			#puts "Sequence.find_col_for:tokens[0] '#{tokens[0]}' == '#{model.to_s}' ? #{tokens[0] == model.to_s}"
			#puts "Sequence.find_col_for:tokens[1] '#{tokens[1]}' == '#{col.to_s}' ? #{tokens[1] == col.to_s}"
			if(tokens[0] == model.to_s && tokens[1] == col.to_s)
			ret=line
			end
		end
		puts "Sequence.find_col_for(#{model}.#{col}):ret=#{ret}"
		ret
	end

	def self.get_conditions(filter)
		nil
	end

end
