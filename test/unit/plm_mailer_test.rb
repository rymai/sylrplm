require File.expand_path("../../test_helper", __FILE__)

class PLMMailerTest < ActionMailer::TestCase
  test "toValidate" do
    @expected.subject = 'PLMMailer#toValidate'
    @expected.body    = read_fixture('toValidate')
    @expected.date    = Time.now

    assert_equal @expected.encoded, PLMMailer.create_toValidate(@expected.date).encoded
  end

  test "validated" do
    @expected.subject = 'PLMMailer#validated'
    @expected.body    = read_fixture('validated')
    @expected.date    = Time.now

    assert_equal @expected.encoded, PLMMailer.create_validated(@expected.date).encoded
  end

end
