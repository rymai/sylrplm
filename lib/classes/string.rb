# frozen_string_literal: true

class String
  def zero?
    ret = false
    if blank?
      ret = true
    else
      str = strip!
      if str.nil?
        if vself = ''
          ret = true
        end
      else
        ret = true if str == ''
      end

    end
  end
end
