require File.expand_path("../../test_helper", __FILE__)

class DocumentTest < ActiveSupport::TestCase
	fixtures :users, :groups, :groups_users, :projects, :projects_users, :statusobjects, :typesobjects
	# Replace this with your real tests.
	test "the truth" do
		assert true
	end

	def test_invalid
		doc = Document.new
		assert !doc.valid?
		assert doc.errors.invalid?(:ident)
		assert doc.errors.invalid?(:designation)
		# bad ident
		doc=Document.new(:ident => "000001")
		assert !doc.valid?
		assert doc.errors.invalid?(:ident)
		assert_equal I18n.translate('activerecord.errors.messages')[:invalid]  , doc.errors.on(:ident)
	end

	def test_unique
		doc1a = Document.new(:ident => "DOC01",
		:designation => "Mon doc")
		assert doc1a.valid?
		assert doc1a.save
		doc1b = Document.new(:ident => "DOC01",
		:designation => "Mon doc")
		assert !doc1b.valid?
		assert_equal I18n.translate('activerecord.errors.messages')[:taken]  , doc1b.errors.on(:ident)
		# revision
		doc1c = Document.new(:ident => "DOC01",
		:revision => "2",
		:designation => "Mon doc revise")
		assert doc1c.valid?
		assert doc1c.save
	end

	def test_with_user
		u=users(:user_admin)
		#puts "u=#{u.inspect}"
		o1 = Document.new(:user => u)
		o1.designation="ma designation"
		#puts "test_with_user:o1=#{o1.inspect}"
		assert o1.valid?
		o1 = Document.new(:ident=>"DOC0003", :owner => u, :group => u.group, :projowner => u.project, :designation=>"ma designation")
		#puts "test_with_user:o1=#{o1.inspect}"
		assert o1.valid?
		o1
	end

	def test_revision
		o1 = test_with_user
		o1r = o1.revise
		assert o1r.nil?
		o1 = o1.promote
		o1 = o1.promote
		assert o1.frozen?
		o1r = o1.revise
		assert o1r.valid?
		assert o1r.save
	end
end
