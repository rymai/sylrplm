# frozen_string_literal: true

#--
# Copyright (c) 2009, John Mettraux, jmettraux@gmail.com
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
# Made in Japan.
#++
require 'ruote/sylrplm/sylrplm'

class HistoryController < ApplicationController
  # ##before_filter :login_required
  # GET /history
  #
  def index
    fname = "#{self.class.name}.#{__method__}"
    LOG.debug(fname) { "params=#{params}" }
    opts = { page: params[:page], order: 'created_at DESC' }

    cs = [:source, :wfid, :event, :participant, :wf_name].each_with_object([[]]) do |p, a|
      if v = params[p]
        a.first << "#{p} = ?"
        a << v
      end
    end

    opts[:conditions] = [cs.first.join(' AND ')] + cs[1..-1] \

    @entries = nil

    unless cs.first.empty?
      # puts "HistoryController.index:opts="+opts.inspect
      @all = opts[:conditions].nil?
    end
    # puts "HistoryController.index:params="+params.inspect
    unless params['fonct'].nil? || params['fonct']['current'].nil?
      if params[:fonct][:current] = 'on_plm_objects'
        @entries = Ruote::Sylrplm::HistoryEntry.all
        # puts "HistoryController.index:on_plm_objects:#{@entries.count}"
      end
    end
    # @entries = Ruote::Sylrplm::HistoryEntry.paginate(opts) if @entries.nil?
    LOG.debug(fname) { "opts=#{opts}" }
    @entries = Ruote::Sylrplm::HistoryEntry.where(opts[:conditions]).order(opts[:order]) if @entries.nil?
    @entries = if @entries.nil?
                 []
               else
                 @entries.to_a
               end
    @entries.to_a.each do |en|
      en.link_attributes = { 'relation' => '' }
    end
    # TODO : XML and JSON
  end

  # GET /history
  # GET /history.xml
  def show
    @entry = Ruote::Sylrplm::HistoryEntry.find(params[:id])
    unless params[:obj_id].nil? || params[:obj_type].nil?
      @object = PlmServices.get_object(params[:obj_type], params[:obj_id])
    end
    respond_to do |format|
      format.html # show.html.erb
      format.xml { render xml: @entry }
    end
  end
end
