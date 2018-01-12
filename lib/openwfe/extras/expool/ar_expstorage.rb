# frozen_string_literal: true

#--
# Copyright (c) 2007-2009, Tomaso Tosolini, John Mettraux OpenWFE.org
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# Made in Italy.
#++

require 'base64'

require 'openwfe/service'

# syl
require 'openwfe/expressions/expression_map'

require 'openwfe/rudefinitions'
require 'openwfe/expool/expstorage'
require 'openwfe/extras/singlecon'
require 'openwfe/expressions/fe_define'

module OpenWFE::Extras
  #
  # A migration for creating/dropping the "expressions" table.
  # 'expressions' are atomic pieces of running process instances.
  #
  class ExpressionTables < ActiveRecord::Migration
    def self.up
      create_table :expressions do |t|
        t.column :fei, :string, null: false
        t.column :wfid, :string, null: false
        t.column :expid, :string, null: false
        # t.column :wfname, :string, :null => false
        t.column :exp_class, :string, null: false

        # t.column :svalue, :text, :null => false
        t.column :svalue, :text, null: false, limit: 1024 * 1024
        #
        # 'value' could be reserved, using 'svalue' instead
        #
        # :limit patch by Maarten Oelering (a greater value
        # could be required in some cases)
      end
      add_index :expressions, :fei
      add_index :expressions, :wfid
      add_index :expressions, :expid
      # add_index :expressions, :wfname
      add_index :expressions, :exp_class
    end

    def self.down
      drop_table :expressions
    end
  end

  #
  # The ActiveRecord wrapper for a ruote FlowExpression instance
  #
  class Expression < ActiveRecord::Base
    include SingleConnectionMixin
  end

  #
  # Storing OpenWFE flow expressions in a database.
  #
  class ArExpressionStorage
    include OpenWFE::ServiceMixin
    include OpenWFE::OwfeServiceLocator
    include OpenWFE::ExpressionStorageBase

    attr_accessor :persist_as_yaml

    #
    # Constructor.
    #
    def initialize(service_name, application_context)
      super()
      service_init(service_name, application_context)

      @persist_as_yaml = (application_context[:persist_as_yaml] == true)

      observe_expool
    end

    #
    # Stores an expression.
    #
    def []=(fei, flow_expression)
      e = Expression.find_by_fei(fei.to_s)

      unless e
        e = Expression.new
        e.fei = fei.to_s
        e.wfid = fei.wfid
        e.expid = fei.expid
        # e.wfname = fei.wfname
      end

      e.exp_class = flow_expression.class.name
      # puts  "ExpressionTables.[]=:flow=#{flow_expression.inspect}"
      e.svalue = @persist_as_yaml ?
        YAML.dump(flow_expression) :
        Base64.encode64(Marshal.dump(flow_expression))
      # puts  "ExpressionTables.[]=:e=#{e.svalue.size}"

      # TODO: syl pour postgresql qui refuse le null
      # ##if e.respond_to? :text
      e.text = 'text' if e.text.nil?
      # #end
      e.save_without_transactions!
    end

    #
    # Retrieves a flow expression.
    #
    def [](fei)
      (e = Expression.find_by_fei(fei.to_s)) ? as_owfe_expression(e) : nil
    end

    #
    # Returns true if there is a FlowExpression stored with the given id.
    #
    def has_key?(fei)
      (Expression.find_by_fei(fei.to_s) != nil)
    end

    #
    # Deletes a flow expression.
    #
    def delete(fei)
      Expression.delete_all(['fei = ?', fei.to_s])
    end

    #
    # Returns the count of expressions currently stored.
    #
    def size
      Expression.count
    end

    alias length size

    #
    # Danger ! Will remove all the expressions in the database.
    #
    def purge
      Expression.delete_all
    end

    #
    # Gather expressions matching certain parameters.
    #
    def find_expressions(options = {})
      conditions = determine_conditions(options)
      # note : this call modifies the options hash...

      #
      # maximize usage of SQL querying
      # #puts "*************** ar_expstorage.find_expressions:conditions=#{conditions} ****************"
      exps = Expression.find(:all, conditions: conditions)

      #
      # do the rest of the filtering

      exps = exps.collect do |exp|
        as_owfe_expression(exp)
      end

      exps.find_all do |fexp|
        does_match?(options, fexp)
      end
    end

    #
    # Fetches the root of a process instance.
    #
    def fetch_root(wfid)
      params = {}

      params[:conditions] = [
        'wfid = ? AND exp_class = ?',
        wfid,
        OpenWFE::DefineExpression.to_s
      ]

      exps = Expression.find(:all, params)

      e = exps.sort { |fe1, fe2| fe1.fei.expid <=> fe2.fei.expid }[0]
      #
      # find the one with the smallest expid

      as_owfe_expression(e)
    end

    #
    # Used only by work/pooltool.ru for storage migrations.
    #
    def each
      return unless block_given?

      Expression.find(:all).each do |e|
        fexp = as_owfe_expression(e)
        yield(fexp.fei, fexp)
      end
    end

    #
    # Closes the underlying database... Does nothing in this implementation.
    #
    def close
      # nothing to do here.
    end

    protected

    #
    # Grabs the options to build a conditions array for use by
    # find().
    #
    # Note : this method, modifies the options hash (it removes
    # the args it needs).
    #
    def determine_conditions(options)
      wfid = options.delete :wfid
      wfid_prefix = options.delete :wfid_prefix
      # parent_wfid = options.delete :parent_wfid

      query = []
      conditions = []

      if wfid
        query << 'wfid = ?'
        conditions << wfid
      elsif wfid_prefix
        query << 'wfid LIKE ?'
        conditions << "#{wfid_prefix}%"
      end

      add_class_conditions options, query, conditions

      conditions = conditions.flatten

      if conditions.empty?
        nil
      else
        conditions.insert(0, query.join(' AND '))
      end
    end

    #
    # Used by determine_conditions().
    #
    def add_class_conditions(options, query, conditions)
      ic = options.delete :include_classes
      ic = Array(ic)

      ec = options.delete :exclude_classes
      ec = Array(ec)

      acc ic, query, conditions, 'OR'
      acc ec, query, conditions, 'AND'
    end

    def acc(classes, query, conditions, join)
      return if classes.empty?

      classes = classes.collect do |kind|
        get_expression_map.get_expression_classes kind
      end
      classes = classes.flatten

      quer = []
      cond = []
      classes.each do |cl|
        quer << if join == 'AND'
                  'exp_class != ?'
                else
                  'exp_class = ?'
        end

        cond << cl.to_s
      end
      quer = quer.join(" #{join} ")

      query << "(#{quer})"
      conditions << cond
    end

    Y_START = /--- !/

    #
    # Extracts the OpenWFE FlowExpression instance from the
    # active record and makes sure its application_context is set.
    #
    def as_owfe_expression(record)
      # puts "================== ar_expstorage.as_owfe_expression:record=#{record}"
      return nil unless record
      # begin
      s = record.svalue

      # #fe = s.match(Y_START) ? YAML.load(s) : ::OpenWFE::Xml::from_xml(s)
      fe = s.match(Y_START) ? YAML.safe_load(s) : Marshal.load(Base64.decode64(s))
      fe.application_context = @application_context
      fe
      # rescue Exception=>exc
      #  puts "================== ar_expstorage.as_owfe_expression:no svalue"
      # nil
      # end
    end
  end
end
