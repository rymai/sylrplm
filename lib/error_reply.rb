# frozen_string_literal: true

class ErrorReply < RuntimeError
  attr_reader :status
  def initialize(msg, status = 400)
    super(msg)
    @status = status
  end
end
