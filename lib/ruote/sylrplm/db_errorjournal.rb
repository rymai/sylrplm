module OpenWFE::Extras
  class DbErrorJournal 
    def add_error(process_error)
      record_error(process_error)
    end
  end
end