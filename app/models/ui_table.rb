class UiTable < ActiveRecord::Base
	include Models::SylrplmCommon
	attr_accessible :id, :ident, :title, :type_table, :description, :pagination, :domain,:ui_columns
	validates_presence_of :ident,:type_table,:ui_columns
	validates_uniqueness_of  :ident
	#
	def column_readonly? attr
		return false
	end

	def modelname
		"ui_table"
	end

	def getMenusAction
		["edit","lifecycle","copy","duplicate","revise","check"]
	end

	def ui_columns_exists?(columns=nil)
		fname= "#{self.class.name}.#{__method__}"
		ret=!get_ui_columns(columns).nil?
		LOG.debug(fname){"<====> ret=#{ret}"}
		ret
	end

	def get_ui_columns(columns=nil)
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug(fname){"columns=#{columns}"}
		ret=[]
		st=0
		if columns.nil?
			cols_idents=ui_columns.split(",")
		else
			cols_idents=columns.split(",")
		end
		LOG.debug(fname){"cols_idents=#{cols_idents}"}
		cols_idents.each do |colident|
			colident=colident.gsub("\n","")
			colident=colident.gsub("\r","")
			colident=colident.gsub(" ","")
			col=UiColumn.find_by_ident(colident)
			LOG.debug(fname){"colident=#{colident} : #{!col.nil?}"}
			unless col.nil?
			ret << col
			else
				st+=1
				msg="Error: colident=#{colident}, col not existing"
				LOG.debug(fname){msg}
				self.errors.add(:base,msg)
			end
		end
		#ret=nil if st!=0
		if st==0
		LOG.debug(fname){"<====> #{ret.size} columns"}
		else
			self.errors.add(:base,"ERROR: can't build columns, Verify the list of columns")
		end
		ret
	end

end
