# frozen_string_literal: true

require File.expand_path('../../spec_helper', __FILE__)

# usage : cd spec ; rspec features/* --format doc

describe Project, type: :feature do
  before :each do
    @user = User.new(login: 'admin', email: 'user@example.com', password: 'admin')
    puts "before:user=#{@user}"
  end

  it 'signs me in' do
    visit '/sessions/new'
    within('#session') do
      fill_in 'session_login', with: 'admin'
      fill_in 'session_password', with: 'admin'
    end
    click_button I18n.translate(:submit_account)
    expect(page).to have_content(I18n.translate(:hello))
  end

  it 'list projects' do
    puts '/sessions/new'
    visit '/sessions/new'
    within('#session') do
      fill_in 'session_login', with: 'admin'
      fill_in 'session_password', with: 'admin'
    end
    click_button I18n.translate(:submit_account)
    puts '/projects'
    visit '/projects'
    expect(page).to have_content(I18n.translate(:project_list))
    within_table('list_objects') do
      puts "expect:#{inspect}:#{page.inspect}"
      expect(page).to have_content('PROJECT-admin')
      expect(page).to have_content('PROJECT-users')
      expect(page).to have_content('PROJET TABLE')
    end
    click_link('PROJECT-users')
    expect(page).to have_content('Projet par defaut pour les users')
    click_link(I18n.translate('edit'))
    within(:form, '#edit_project') do
      fill_in 'project_designation', with: 'Projet pour users'
    end
    click_button(:project_submit)
    # expect(size).to eq(30)
  end
end
