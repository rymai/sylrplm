class UiColumn < ActiveRecord::Base
	include Models::SylrplmCommon
	attr_accessible :id, :ident, :type_column, :description ,:visible_guest, :visible_user, :visible_admin, :visible_support
	attr_accessible :editable, :type_index, :type_show, :type_editable  ,:type_editable_file,:sortable,:domain
	attr_accessible :belong_object,:belong_method,:input_size,:value_mini,:value_maxi
	validates_presence_of :ident
	validates_uniqueness_of :ident

	def getTypesIndex
		["explorer","text","comma","comma_links","image"]
	end

def getTypesShow
		["explorer","text","textarea","comma","comma_links","image"]
	end

	def getTypesEditable
		["input_text", "input_textarea","input_integer", "input_float", "input_file", "input_check","input_radio","select","search"]
	end

	def getTypesEditableFile
		["*.png","*.gif"]
	end

	def method
		"ident"
	end

end
