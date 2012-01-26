

class PlmProcessException < Exception
  attr_reader :code
  def initialize (msg, code=10000)
    super(msg)
    @code = code
  end
end



