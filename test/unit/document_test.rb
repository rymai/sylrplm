# frozen_string_literal: true

require File.expand_path('../../test_helper', __FILE__)

class DocumentTest < ActiveSupport::TestCase
  fixtures :documents, :users, :typesobjects, :statusobjects, :statusobjects_nexts, :statusobjects_previous, :relations

  def test_invalid
    fname = "#{self.class.name}.#{__method__}:"
    doc = Document.new
    assert !doc.valid?
    assert doc.invalid?(:ident)
    assert doc.invalid?(:designation)
    # bad ident
    doc = Document.new(ident: '000001')
    assert !doc.valid?
    assert doc.invalid?(:ident)
    assert_equal [I18n.translate('activerecord.errors.messages')[:invalid]], doc.errors[:ident]
  end

  def test_unique
    fname = "#{self.class.name}.#{__method__}:"
    doc1a = Document.new(ident: 'DOC01',revision: "0",
                         designation: 'Mon doc', owner_id: 1)
    assert doc1a.save
    assert doc1a.valid?
    doc1b = Document.new(ident: 'DOC01',revision: "0",
                         designation: 'Mon doc', owner_id: 1)
    st=doc1b.save
    puts "#{fname} st_save=#{st} doc1a=#{doc1a.id} #{doc1a} doc1b=#{doc1b.id} #{doc1b}"
    assert !doc1b.valid?
    assert_equal [I18n.translate('activerecord.errors.messages')[:taken]], doc1b.errors[:ident]
    # revision
    doc1c = Document.new(ident: 'DOC01',
                         revision: '2',
                         designation: 'Mon doc revise', owner_id: 1)
    doc1c.save
    assert doc1c.valid?
    assert doc1c.save
  end

  def test_with_user
    fname = "#{self.class.name}.#{__method__}:"
    u = users(:user_admin)
    o1 = Document.new(ident: 'DOC01', designation: 'ma designation', user: u)
    #puts "test_with_user:o1 1=#{o1.inspect}"
    assert o1.valid?
    o2 = Document.new(ident: 'DOC0003', statusobject_id: 4, owner: u, group: u.group, projowner: u.project, designation: 'ma designation')
    #puts "test_with_user:o1 2=#{o1.inspect}"
    assert o2.valid?
    o2
  end

  def test_revision
    fname = "#{self.class.name}.#{__method__}:"
    puts ">>>>#{fname}"
    u = users(:user_admin)
    o1= Document.new(id: 100000,ident: 'DOC0003', revision: 0, statusobject_id: 4, owner: u, group: u.group, projowner: u.project, designation: 'ma designation')
    puts "#{fname} o1 statusobject_id=#{o1.statusobject_id}"
    assert o1.save
    puts "#{fname}: o1 apres save=#{o1.inspect} "
    puts "#{fname}: o1 apres save statusobject=#{o1.statusobject} next_status=#{o1.next_status}"
    o1 = o1.promote
    o1 = o1.promote
    LOG.debug(fname) { " o1=#{o1.id} next_status=#{o1.next_status}" }
    assert o1.frozen?
    o1r = o1.revise
    assert o1r.valid?
    assert o1r.save
     puts "<<<<#{fname}"
  end
end
