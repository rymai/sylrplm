

# frozen_string_literal: true

class PlmProcessException < RuntimeError
  attr_reader :code
  def initialize(msg, code = 10_000)
    super(msg)
    @code = code
  end
end
