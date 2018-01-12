# frozen_string_literal: true

require File.expand_path('../../test_helper', __FILE__)

class CheckTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test 'the truth' do
    assert true
  end

  def test_invalid
    o1 = Check.new
    assert !o1.valid?
    assert o1.errors.invalid?(:checkobject_plmtype)
    assert o1.errors.invalid?(:checkobject_id)
    assert o1.errors.invalid?(:out_user)
    assert o1.errors.invalid?(:out_group)
    assert o1.errors.invalid?(:out_reason)
    u = users(:user_admin)
    o2 = Check.new(user: u)
    assert !o2.valid?
    o3 = Check.new(checkobject_plmtype: 'plmtype',
                   checkobject_id: 1,
                   out_user: u,
                   out_group: u.group,
                   out_reason: 'reason 1',
                   out_date: Time.now.utc)
    assert o3.valid?
    assert o3.save
  end

  def test_check_in
    u = users(:user_admin)
    o1 = Check.new(checkobject_plmtype: 'plmtype',
                   checkobject_id: 1,
                   out_user: u,
                   out_group: u.group,
                   out_reason: 'reason 1',
                   out_date: Time.now.utc)
    assert o1.valid?
    assert o1.save
    assert !o1.update_attributes(status: 10, in_user: u, in_group: u.group, in_reason: 'reason 1', in_date: Time.now.utc)
    assert_equal I18n.translate('activerecord.errors.messages')[:status_not_valid], o1.errors.on(:status)
    assert o1.update_attributes(status: ::Check::CHECK_STATUS_IN, in_user: u, in_group: u.group, in_reason: 'reason 1', in_date: Time.now.utc)
  end
end
