require File.dirname(__FILE__)+'/../test_helper'

class DocumentTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
  
  def test_invalid
    doc=Document.new
    assert !doc.valid?
    assert doc.errors.invalid?(:ident)
    assert doc.errors.invalid?(:designation)
  end
end
