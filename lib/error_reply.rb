class ErrorReply < Exception
  attr_reader :status
  def initialize (msg, status = 400)
    super(msg)
    @status = status
  end
end
