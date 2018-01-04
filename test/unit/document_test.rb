require File.expand_path("../../test_helper", __FILE__)

class DocumentTest < ActiveSupport::TestCase
	fixtures :documents, :users

	def test_invalid
		fname= "#{self.class.name}.#{__method__}:"
		doc = Document.new
		assert !doc.valid?
		assert doc.invalid?(:ident)
		assert doc.invalid?(:designation)
		# bad ident
		doc=Document.new(:ident => "000001")
		assert !doc.valid?
		assert doc.invalid?(:ident)
		assert_equal [I18n.translate('activerecord.errors.messages')[:invalid]], doc.errors[:ident]
	end

	def test_unique
		fname= "#{self.class.name}.#{__method__}:"
		doc1a = Document.new(:ident => "DOC01",
		:designation => "Mon doc",:owner_id=>1)
		assert doc1a.valid?
		assert doc1a.save
		doc1b = Document.new(:ident => "DOC01",
		:designation => "Mon doc",:owner_id=>1)
		assert !doc1b.valid?
		assert_equal [I18n.translate('activerecord.errors.messages')[:taken]], doc1b.errors[:ident]
		# revision
		doc1c = Document.new(:ident => "DOC01",
		:revision => "2",
		:designation => "Mon doc revise",:owner_id=>1)
		assert doc1c.valid?
		assert doc1c.save
	end

	def test_with_user
		fname= "#{self.class.name}.#{__method__}:"
		u=users(:user_admin)
		o1 = Document.new(:ident => "DOC01", :designation => "ma designation", :user => u)
		#puts "test_with_user:o1=#{o1.inspect}"
		assert o1.valid?
		o1 = Document.new(:ident=>"DOC0003", :owner => u, :group => u.group, :projowner => u.project, :designation=>"ma designation")
		#puts "test_with_user:o1=#{o1.inspect}"
		assert o1.valid?
		o1
	end

	def test_revision
		fname= "#{self.class.name}.#{__method__}:"
		o1 = test_with_user
		assert o1.save
		LOG.debug(fname) {"#{fname}: o1=#{o1.id} next_status=#{o1.next_status}"}
		#o1r = o1.revise
		#assert o1r.nil?
		o1 = o1.promote
		o1 = o1.promote
		LOG.debug(fname) {" o1=#{o1.id} next_status=#{o1.next_status}"}
		assert o1.frozen?
		o1r = o1.revise
		assert o1r.valid?
		assert o1r.save
	end
end
