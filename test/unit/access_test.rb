# frozen_string_literal: true

require File.expand_path('../../test_helper', __FILE__)

class AccessTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test 'the truth' do
    assert true
  end

  def test_invalid
    o1 = Access.new
    assert !o1.valid?
    assert o1.errors.invalid?(:controller)
    assert o1.errors.invalid?(:action)
    assert o1.errors.invalid?(:roles)
  end

  def test_unique
    o1 = Access.new(controller: 'Part',
                    action: 'action1',
                    roles: 'creator')
    # puts "o1=#{o1.inspect}"
    assert o1.valid?
    assert o1.save

    o2 = Access.new(controller: 'Part',
                    action: 'action1',
                    roles: 'designer')
    # puts "o2=#{o1.inspect}"
    assert !o2.valid?
    assert_equal I18n.translate('activerecord.errors.messages')[:taken], o2.errors.on(:action)
    # controller
    o3 = Access.new(controller: 'Customer',
                    action: 'action1',
                    roles: 'designer')
    # puts "o3=#{o3.inspect}"
    assert o3.valid?
    assert o3.save
  end
end
