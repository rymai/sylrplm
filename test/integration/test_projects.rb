require File.expand_path("../../test_helper", __FILE__)

class TestProject < CapybaraTestCase
	fixtures :all
	include Capybara::DSL

	puts "debut"

	session = Capybara::Session.new(:selenium)
	session.visit "http://localhost:3000"

	#test "# visit projects" do
	def test1
		visit('/projects')
		click_on(I18n.translate('mnu_projects'))
		if session.has_content?("Ruby on Rails web development")
			puts "All shiny, captain!"
		else
			puts ":( no tagline fonud, possibly something's broken"
		#exit(-1)
		end
	end

	#test "# visible guests should be equal to the total # of guests" do
	def test2
		@obj = Project.find(:first, :order => 'random()')
		visit("/project/#{@obj.id}")
		# Au chargement, les invitès ne doivent pas figurer dans la page
		assert_equal 0, all('.project').size
		#click_on "Show guests"
		# On doit voir le bon nombre d'invités une fois le lien cliqué
		#assert has_css?('.guest', :count => @event.guests.size)
	end

end
