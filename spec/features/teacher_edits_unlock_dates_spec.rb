require 'spec_helper'

feature 'Teacher edits unlock dates', feature: true do
  include IntegrationTestActions

  before :each do
    organization = FactoryGirl.create :accepted_organization, slug: 'slug'
    @teacher = FactoryGirl.create :user, password: 'xooxer'
    @user = FactoryGirl.create :user, password: 'foobar'
    Teachership.create! user: @teacher, organization: organization

    repo_path = @test_tmp_dir + '/fake_remote_repo'
    create_bare_repo(repo_path)
    course = FactoryGirl.create :course, source_url: repo_path
    repo = clone_course_repo(course)
    repo.copy_simple_exercise('MyExercise')
    repo.add_commit_push
    course.refresh

    course.exercise_group_by_name('').group_unlock_conditions = ['1.1.2011'].to_json
    UncomputedUnlock.create_all_for_course_eager(course)

    visit '/'
  end

  scenario 'Teacher sees default unlock dates' do
    log_in_as(@teacher.login, 'xooxer')
    visit '/org/slug/courses/1'
    click_link 'Manage unlock dates'

    expect(page).to have_field('empty_group_0', with: '1.1.2011')
  end

  scenario 'Teacher sets new unlock date' do
    log_in_as(@teacher.login, 'xooxer')
    visit '/org/slug/courses/1'
    click_link 'Manage unlock dates'

    fill_in 'empty_group_0', with: '4.6.2015'
    click_button 'Save changes'
    expect(page).to have_content('Successfully set unlock dates.')
    expect(page).to have_field('empty_group_0', with: '4.6.2015')
  end

  scenario 'Exercises are locked if teacher sets unlock date to be later than current time' do
    log_in_as(@teacher.login, 'xooxer')
    visit '/org/slug/courses/1'
    click_link 'Manage unlock dates'

    fill_in 'empty_group_0', with: "#{Time.now + 3.days}"
    click_button 'Save changes'
    expect(page).to have_content('Successfully set unlock dates.')
    expect(page).to have_content('(locked)')
  end

  scenario 'Exercises are unlocked if teacher sets unlock date to be earlier than current time' do
    log_in_as(@teacher.login, 'xooxer')
    visit '/org/slug/courses/1'
    click_link 'Manage unlock dates'

    fill_in 'empty_group_0', with: "#{Time.now - 3.days}"
    click_button 'Save changes'
    expect(page).to have_content('Successfully set unlock dates.')
    expect(page).not_to have_content('(locked)')
  end

  scenario 'Teacher can set empty unlock date' do
    log_in_as(@teacher.login, 'xooxer')
    visit '/org/slug/courses/1'
    click_link 'Manage unlock dates'

    fill_in 'empty_group_0', with: ''
    click_button 'Save changes'
    expect(page).to have_content('Successfully set unlock dates.')
    expect(page).to have_field('empty_group_0', with: '')
  end

  scenario 'Teacher cant edit unlock date with wrong format' do
    log_in_as(@teacher.login, 'xooxer')
    visit '/org/slug/courses/1'
    click_link 'Manage unlock dates'

    fill_in 'empty_group_0', with: '32.13.abcd'
    click_button 'Save changes'
    expect(page).not_to have_content('Successfully set unlock dates.')
    expect(page).to have_content('Invalid syntax')
    expect(page).to have_field('empty_group_0', with: '1.1.2011')
  end

  scenario 'Non-teacher doesnt have access to editing unlock dates' do
    log_in_as(@user.login, 'foobar')
    visit '/org/slug/courses/1'
    expect(page).not_to have_content('Manage unlock dates')
  end
end
