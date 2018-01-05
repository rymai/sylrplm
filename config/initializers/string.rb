# frozen_string_literal: true

class String
  def to_msgkey
    fname = "#{self.class.name}.#{__method__}"
    LOG.debug(fname) { "str to change=#{self}" }
    ret = tr('.', '_')
    ret.tr(' ', '_')
    LOG.debug(fname) { "str to change : #{self} = #{ret}" }
    ret
  end
end
