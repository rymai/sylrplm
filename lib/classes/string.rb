class String
	def zero?
		ret = false
		if self.blank?
		ret=true
		else
			str=self.strip!
			if str.nil?
				if vself=""
				ret=true
				end
			else
				if str==""
				ret=true
				end
			end

		end
	end
end