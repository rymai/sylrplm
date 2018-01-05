# frozen_string_literal: true

class UiTable < ActiveRecord::Base
  include Models::SylrplmCommon
  attr_accessible :id, :ident, :title, :type_table, :description, :pagination, :domain, :ui_columns
  validates_presence_of :ident, :type_table, :ui_columns
  validates_uniqueness_of :ident
  #
  def column_readonly?(_attr)
    false
  end

  def modelname
    'ui_table'
  end

  def getMenusAction
    %w[edit lifecycle copy duplicate revise check]
  end

  def ui_columns_exists?(columns = nil)
    fname = "#{self.class.name}.#{__method__}"
    ret = !get_ui_columns(columns).nil?
    LOG.debug(fname) { "<====> ret=#{ret}" }
    ret
  end

  def get_ui_columns(columns = nil)
    fname = "#{self.class.name}.#{__method__}"
    LOG.debug(fname) { "columns=#{columns}" }
    ret = []
    st = 0
    cols_idents = if columns.nil?
                    ui_columns.split(',')
                  else
                    columns.split(',')
                  end
    LOG.debug(fname) { "cols_idents=#{cols_idents}" }
    cols_idents.each do |colident|
      colident = colident.delete("\n")
      colident = colident.delete("\r")
      colident = colident.delete(' ')
      col = UiColumn.find_by_ident(colident)
      LOG.debug(fname) { "colident=#{colident} : #{!col.nil?}" }
      if col.nil?
        st += 1
        msg = "Error: colident=#{colident}, col not existing"
        LOG.debug(fname) { msg }
        errors.add(:base, msg)
      else
        ret << col
      end
    end
    # ret=nil if st!=0
    if st == 0
      LOG.debug(fname) { "<====> #{ret.size} columns" }
    else
      errors.add(:base, "ERROR: can't build columns, Verify the list of columns")
    end
    ret
  end
end
