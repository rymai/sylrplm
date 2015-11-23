require File.expand_path("../../test_helper", __FILE__)

class PlmMailerTest < ActionMailer::TestCase
	test "toValidate" do
		fname= "#{self.class.name}.#{__method__}:"
		u=users(:user_admin)
		@expected.subject = 'PLMMailer#toValidate'
		@expected.body    = read_fixture('toValidate')
		@expected.date    = Time.now
		@object = Document.new(:user => u)
		@object.designation="ma designation"
		st=@object.save
		LOG.debug(fname) {"stsave=#{st} errors=#{@object.errors.full_messages} object=#{@object.inspect} "}
		#assert_equal @expected.encoded, PlmMailer.create_toValidate(@object, users(:user_admin), "", [users(:user_admin)], @expected.date).encoded
	end

	test "validated" do
		fname= "#{self.class.name}.#{__method__}:"
		u=users(:user_admin)
		@expected.subject = 'PLMMailer#validated'
		 @expected.body    = read_fixture('validated')
		@expected.date    = Time.now
		@object = Document.new(:user => u)
		@object.designation="ma designation"
		st=@object.save
		LOG.debug(fname) {"stsave=#{st} errors=#{@object.errors.full_messages}s object=#{@object.inspect}"}
		#assert_equal @expected.encoded, PlmMailer.create_validated(@object, users(:user_admin), "", [users(:user_admin)], @expected.date).encoded
	end

end
