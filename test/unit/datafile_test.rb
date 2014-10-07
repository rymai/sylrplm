require File.expand_path("../../test_helper", __FILE__)

class DatafileTest < ActiveSupport::TestCase
	# Replace this with your real tests.
	test "the truth" do
		assert true
	end

	def test_invalid
		o1 = Datafile.new
		assert !o1.valid?
		assert o1.errors.invalid?(:ident)
		assert o1.errors.invalid?(:typesobject)
		assert o1.errors.invalid?(:revision)
		assert o1.errors.invalid?(:volume)
		assert o1.errors.invalid?(:owner)
		assert o1.errors.invalid?(:group)
		assert o1.errors.invalid?(:projowner)
	end

	def test_unique
		u = users(:user_admin)
		d1 = Datafile.new(:ident => "DF01",
		:typesobject_id => "646247456",
		:revision => 1,
		:volume => volumes(:volume_one) ,
		:owner => u,
		:group => u.group,
		:projowner => u.project)
		assert d1.valid?
		assert d1.save
		d2 = Datafile.new(:ident => "DF01",
		:typesobject_id => "646247456",
		:revision => 1,
		:volume => volumes(:volume_one) ,
		:owner => u,
		:group => u.group,
		:projowner => u.project)
		assert !d2.valid?
		assert_equal I18n.translate('activerecord.errors.messages')[:taken]  , d2.errors.on(:ident)
		# revision
		d3 = Datafile.new(:ident => "DF01",
		:typesobject_id => "646247456",
		:revision => 2,
		:volume => volumes(:volume_one) ,
		:owner => u,
		:group => u.group,
		:projowner => u.project)
		assert d3.valid?
		assert d3.save
	end

	def test_with_user
		u = users(:user_admin)
		#puts "u=#{u.inspect}"
		o1 = Datafile.new(:user => u)
		#puts "test_with_user:o1=#{o1.inspect}"
		assert !o1.valid?
		assert o1.errors.invalid?(:ident)
		assert o1.errors.invalid?(:typesobject)
		#assert o1.errors.invalid?(:revision)
		assert o1.errors.invalid?(:volume)
		o1 = Datafile.new(:ident=>"DF0003",
		:typesobject_id => "646247456",
		:revision => 1,
		:volume => volumes(:volume_one) ,
		:owner => u,
		:group => u.group,
		:projowner => u.project)
		#puts "test_with_user:o1=#{o1.inspect}"
		assert o1.valid?
		o1
	end

end
