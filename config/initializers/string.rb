class String

	def to_msgkey
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug(fname){"str to change=#{self}"}
		ret=self.gsub(".","_")
		ret.gsub(" ","_")
		LOG.debug(fname){"str to change : #{self} = #{ret}"}
		ret
	end
end