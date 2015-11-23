require File.expand_path("../../test_helper", __FILE__)

class CustomerTest < ActiveSupport::TestCase
	# Replace this with your real tests.
	test "the truth" do
		assert true
	end

	def test_invalid
		customer = Customer.new
		assert !customer.valid?
		assert customer.errors.invalid?(:ident)
		assert customer.errors.invalid?(:designation)
	end

	def test_unique_ident
		customer1a = Customer.new(:ident => "Customer01",
		:designation => "Mon customer",:owner_id=>1)
		assert customer1a.valid?
		assert customer1a.save
		customer1b = Customer.new(:ident => "Customer01",
		:designation => "Mon customer",:owner_id=>1)
		assert !customer1b.valid?
		assert_equal  I18n.translate('activerecord.errors.messages')[:taken] , customer1b.errors.on(:ident)
	end

end
