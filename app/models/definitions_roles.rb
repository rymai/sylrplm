#
# Between roles and definitions
#
class DefinitionsRoles < ActiveRecord::Base
	belongs_to :role
	belongs_to :definition
	def self.get_conditions(filter)
		nil
	end

	def before_save
		self.domain = role.domain
		self.domain = definition.domain if self.domain.nil?
	end

end

