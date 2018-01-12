# frozen_string_literal: true

require 'openwfe/extras/expool/db_errorjournal'
module OpenWFE::Extras
  class DbErrorJournal
    def add_error(process_error)
      record_error(process_error)
    end
  end
end
