# frozen_string_literal: true

#--
# Copyright (c) 2008-2009, John Mettraux, jmettraux@gmail.com
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

require 'openwfe/expool/history'
require 'openwfe/extras/singlecon'

module OpenWFE::Extras
  #
  # The migration for the DbHistory table
  #
  class HistoryTables < ActiveRecord::Migration
    def self.up
      create_table :history do |t|
        t.column :created_at, :timestamp
        t.column :source, :string, null: false
        t.column :event, :string, null: false
        t.column :wfid, :string
        t.column :wfname, :string
        t.column :wfrevision, :string
        t.column :fei, :string
        t.column :participant, :string
        t.column :message, :string # empty is ok
      end

      add_index :history, :created_at
      add_index :history, :source
      add_index :history, :event
      add_index :history, :wfid
      add_index :history, :wfname
      add_index :history, :wfrevision
      add_index :history, :participant
    end

    def self.down
      drop_table :history
    end
  end

  class DbHistory < OpenWFE::History
    # def initialize (service_name, application_context)
    #  super
    # end

    def log(source, event, *args)
      do_log(source, event, *args)
    end

    protected

    def do_log(source, event, *args)
      fei = get_fei(args)
      wi = get_workitem(args)

      begin
        Ruote::Sylrplm::HistoryEntry.log!(
          source, event,
          fei: fei,
          message: get_message(source, event, args),
          participant: wi.respond_to?(:participant_name) ?
            wi.participant_name : nil
        )
      rescue Exception => e
        # p e
        lerror { "db_history logging failure : #{e}" }
      end
    end
  end

  #
  # An extension of the DbHistory that uses the engine's workqueue. Insertions
  # into database are queued (as well as expool events).
  #
  # Seems to be slightly faster (0.8s gain for a 11s test).
  #
  # Currently in use in ruote-rest.
  #
  class QueuedDbHistory < DbHistory
    def log(source, event, *args)
      get_workqueue.push(self, :do_log, source, event, *args)
    end
  end
end
