# un abonnement appartient a un seul user  / a subscription have one and only one owner
# un user peut avoir plusieurs abonnements / a user could have several subscription
# un abonnement a un nom unique / a subscription have a uniq name
# un abonnement s'applique sur un ou plusieurs types d'objets / a subscription is applicable on one or several objets type
# les objets soumis a l'abonnement appartiennent a : / Items subject to the subscription belong to
# - un ou plusieurs groupes / one or several groups
# - un ou plusieurs projets / one or several projects
#
class Subscription < ActiveRecord::Base
	include Models::SylrplmCommon
	# pour def_user
	include Models::PlmObject
	#
	validates_presence_of :name, :designation
	validates_uniqueness_of :name
	#
	belongs_to :owner, :class_name => "User"
	# les types d'objet pour lesquels l'abonnement s' applique
	has_and_belongs_to_many :fortypesobject, :class_name => "Typesobject"
	# les projets pour lesquels l'abonnement s' applique
	has_and_belongs_to_many :inproject, :class_name => "Project"
	# les groupes pour lesquels l'abonnement s' applique
	has_and_belongs_to_many :ingroup, :class_name => "Group"
	#
	def user=(user)
		def_user(user)
	end

	def ident
		name
	end

	def self.get_conditions(filter)
		filter = filter.gsub("*","%")
		ret = {}
		if filter.present?
			ret[:qry] = "name LIKE :v_filter or designation LIKE :v_filter or description LIKE :v_filter or #{qry_owner_id} "
			ret[:values] = { v_filter: filter }
		end
		ret
	end

	def ingroup_array
		ret=[]
		self.ingroup(:all,:select => "name").each do |o| 
			ret << o.name
		end
		ret
	end

	def inproject_array
		ret=[]
		self.inproject(:all,:select => "ident").each do |o| 
			ret << o.ident
		end
		ret
	end

end
