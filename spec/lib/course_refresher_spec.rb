require 'spec_helper'

describe CourseRefresher do
  include GitTestActions

  let(:repo_path) { "#{@test_tmp_dir}/fake_remote_repo" }
  let(:repo_url) { "file://#{repo_path}" }

  let!(:course) { Course.create!(:name => 'TestCourse', :source_backend => 'git', :source_url => repo_url) }

  before :each do
    create_bare_repo(repo_path)
  end

  let(:local_clone) { clone_course_repo(course) }

  let(:refresher) { CourseRefresher.new }

  it "should discover new exercises" do
    add_exercise('MyExercise')
    refresher.refresh_course(course)
    course.exercises.should have(1).item
    course.exercises[0].name.should == 'MyExercise'
  end

  it "should discover new exercises in subdirectories" do
    add_exercise('MyCategory/MyExercise')
    add_exercise('MyCategory/MySubcategory/MyExercise')
    refresher.refresh_course(course)
    course.exercises.should have(2).items
    names = course.exercises.map &:name
    names.should include('MyCategory-MyExercise')
    names.should include('MyCategory-MySubcategory-MyExercise')
  end

  it "should allow duplicate available point names for different exercises" do
    add_exercise('MyCategory/MyExercise')
    refresher.refresh_course(course)
    add_exercise('MyCategory/MySubcategory/MyExercise')
    refresher.refresh_course(course)
    course.exercises.should have(2).items
    names = course.exercises.map &:name
    names.should include('MyCategory-MyExercise')
    names.should include('MyCategory-MySubcategory-MyExercise')

    points0 = course.exercises[0].available_points.length
    points1 = course.exercises[1].available_points.length
    points0.should_not == 0
    points1.should_not == 0
    points0.should == points1

    uniq_points = course.available_points.map(&:name).uniq.length
    uniq_points.should == points0
    uniq_points.should == points1
  end


  it "should reload course metadata" do
    course.hide_after.should be_nil

    change_course_metadata_file 'hide_after' => "2011-07-01 13:00"
    refresher.refresh_course(course)
    course.hide_after.should == Time.parse("2011-07-01 13:00") # local time zone

    change_course_metadata_file 'hide_after' => nil
    refresher.refresh_course(course)
    course.hide_after.should == nil

    change_course_metadata_file 'hidden' => true
    refresher.refresh_course(course)
    course.should be_hidden

    change_course_metadata_file 'spreadsheet_key' => 'qwerty'
    refresher.refresh_course(course)
    course.spreadsheet_key.should == 'qwerty'
  end

  it "should fail if the course metadata file cannot be parsed" do
    change_course_metadata_file('xooxer', :raw => true)

    expect { refresher.refresh_course(course) }.to raise_error
  end

  it "should load exercise metadata with defaults from superdirs" do
    add_exercise('MyExercise', :commit => false)
    change_metadata_file(
      'metadata.yml',
      {'deadline' => "2000-01-01 00:00", 'gdocs_sheet' => 'xoo'},
      {:commit => false}
    )
    change_metadata_file(
      'MyExercise/metadata.yml',
      {'deadline' => "2012-01-02 12:34"},
      {:commit => true}
    )

    refresher.refresh_course(course)

    course.exercises.first.deadline.should == Time.parse("2012-01-02 12:34")
    course.exercises.first.gdocs_sheet.should == "xoo"
  end

  it "should load changed exercise metadata" do
    add_exercise('MyExercise', :commit => false)
    change_metadata_file(
      'metadata.yml',
      {'deadline' => "2000-01-01 00:00", 'gdocs_sheet' => 'xoo'},
      {:commit => false}
    )
    change_metadata_file('MyExercise/metadata.yml',
      {'deadline' => "2012-01-02 12:34"},
      {:commit => true}
    )
    refresher.refresh_course(course)

    change_metadata_file(
      'metadata.yml',
      {'deadline' => "2013-01-01 00:00", 'gdocs_sheet' => 'xoo'},
      {:commit => false}
    )
    change_metadata_file(
      'MyExercise/metadata.yml',
      {'gdocs_sheet' => "foo"},
      {:commit => true}
    )
    refresher.refresh_course(course)

    course.exercises.first.deadline.should == Time.parse("2013-01-01 00:00")
    course.exercises.first.gdocs_sheet.should == "foo"
  end

  it "should delete removed exercises from the database" do
    add_exercise('MyExercise')
    refresher.refresh_course(course)

    delete_exercise('MyExercise')
    refresher.refresh_course(course)

    course.exercises.should have(0).items
  end

  it "should restore exercises that are removed and subsequently readded" do
    add_exercise('MyExercise')
    refresher.refresh_course(course)

    delete_exercise('MyExercise')
    refresher.refresh_course(course)

    add_exercise('MyExercise')
    refresher.refresh_course(course)

    course.exercises.should have(1).items
  end

  it "should cope with exercises that use Java packages" do
    add_exercise('MyExercise', :fixture_name => 'ExerciseWithPackages')
    refresher.refresh_course(course)

    course.exercises.should have(1).items
    exercise = course.exercises.first
    exercise.name.should == 'MyExercise'
    exercise.available_points.map(&:name).should include('packagedtest')
  end

  it "should scan the exercises for available points" do
    add_exercise('MyExercise')
    refresher.refresh_course(course)

    points = course.exercises.where(:name => 'MyExercise').first.available_points
    points.map(&:name).should include('addsub')
  end

  it "should delete previously available points that are no longer available" do
    add_exercise('MyExercise')
    refresher.refresh_course(course)
    delete_exercise('MyExercise')
    refresher.refresh_course(course)

    AvailablePoint.all.should be_empty
  end

  it "should never delete awarded points" do
    add_exercise('MyExercise')
    refresher.refresh_course(course)

    exercise = course.exercises.first
    sub = Factory.create(:submission, :course => course, :exercise_name => exercise.name)
    awarded_point = AwardedPoint.create!({
      :course => course,
      :user => sub.user,
      :submission => sub,
      :name => AvailablePoint.first.name
    })

    delete_exercise('MyExercise')
    refresher.refresh_course(course)

    AwardedPoint.all.should include(awarded_point)
  end

  it "should generate stub versions of exercises" do
    # Tested more thoroughly in lib/course_refresher/exercise_file_filter_spec.rb
    add_exercise('MyExercise')

    refresher.refresh_course(course)
    
    stub = Exercise.find_by_name('MyExercise').stub_path
    
    simple_stuff = File.read(stub + '/src/SimpleStuff.java')
    simple_stuff.should_not include('return a + b;')
    simple_stuff.should include('return 0;')
    simple_stuff.should_not include('STUB:')
    
    File.should_not exist(stub + '/test/SimpleHiddenTest.java')
  end
  
  it "should generate solution versions of exercises" do
    # Tested more thoroughly in lib/course_refresher/exercise_file_filter_spec.rb
    add_exercise('MyExercise')

    refresher.refresh_course(course)
    
    solution = Exercise.find_by_name('MyExercise').solution_path
    
    simple_stuff = File.read(solution + '/src/SimpleStuff.java')
    simple_stuff.should include('return a + b;')
    simple_stuff.should_not include('BEGIN SOLUTION')
    simple_stuff.should_not include('return 0;')
    
    File.should_not exist(solution + '/test/SimpleHiddenTest.java')
  end
  
  it "should generate zips from the stubs" do
    add_exercise('MyExercise')
    add_exercise('MyCategory/MyExercise')

    refresher.refresh_course(course)

    File.should exist(course.zip_path + '/MyExercise.zip')
    File.should exist(course.zip_path + '/MyCategory-MyExercise.zip')
  end

  it "should not include hidden tests in the zips" do
    add_exercise('MyExercise')
    refresher.refresh_course(course)

    sh!('unzip', course.zip_path + '/MyExercise.zip')
    File.should_not exist('MyExercise/test/SimpleHiddenTest.java')
    File.should exist('MyExercise/test/SimpleTest.java')
  end

  it "should not include metadata files in the zips" do
    local_repo = add_exercise('MyExercise')
    local_repo.write_file('MyExercise/metadata.yml', 'foo: bar')
    local_repo.write_file('MyExercise/non-metadata.yml', 'foo: bar')
    local_repo.add_commit_push
    refresher.refresh_course(course)

    sh!('unzip', course.zip_path + '/MyExercise.zip')
    File.should_not exist('MyExercise/metadata.yml')
    File.should exist('MyExercise/non-metadata.yml')
  end

  it "should not remake zip files of removed exercises" do
    add_exercise('MyCategory/MyExercise')
    refresher.refresh_course(course)

    File.should exist(course.zip_path + '/MyCategory-MyExercise.zip')

    FileUtils.rm_rf "#{local_clone.path}/MyCategory/MyExercise"
    local_clone.add_commit_push
    refresher.refresh_course(course)

    File.should_not exist(course.zip_path + '/MyCategory-MyExercise.zip')
  end

  it "should delete the old cache directory" do
    old_path = course.cache_path
    refresher.refresh_course(course)
    new_path = course.cache_path

    new_path.should_not == old_path
    File.should exist(new_path)
    File.should_not exist(old_path)
  end

  it "should overwrite the new cache directory if it happens to exist" do
    expected_path = course.cache_path.gsub('0', '1')
    FileUtils.mkdir_p(expected_path)
    FileUtils.touch(expected_path + '/foo.txt')

    refresher.refresh_course(course)

    course.cache_path.should == expected_path
    File.should_not exist(expected_path + '/foo.txt')
  end
  
  it "should store the checksum of each exercise's files in the database" do
    local_repo = add_exercise('MyExercise')
    local_repo.write_file('MyExercise/foo.txt', 'something')
    local_repo.add_commit_push
    
    refresher.refresh_course(course)
    cs1 = course.exercises.first.checksum
    
    local_repo.write_file('MyExercise/foo.txt', 'something else')
    local_repo.add_commit_push
    local_repo.write_file('MyExercise/foo.txt', 'something')
    local_repo.add_commit_push
    
    refresher.refresh_course(course)
    cs2 = course.exercises.first.checksum
    
    local_repo.write_file('MyExercise/foo.txt', 'something else')
    local_repo.add_commit_push
    refresher.refresh_course(course)
    cs3 = course.exercises.first.checksum
    
    [cs1, cs2, cs3].each {|cs| cs.should_not be_blank }
    cs1.should == cs2 # Only file contents should be checksummed
    cs2.should_not == cs3
  end

  describe "on failure" do
    def cause_failure
      change_course_metadata_file('xooxer', :raw => true)
    end

    it "should not leave the new cache directory lying around after a failure" do
      cause_failure
      expect { refresher.refresh_course(course) }.to raise_error

      File.should_not exist(course.cache_path)
    end

    it "should not delete the old cache directory after a failure" do
      refresher.refresh_course(course)
      old_path = course.cache_path
      cause_failure
      expect { refresher.refresh_course(course) }.to raise_error

      File.should exist(old_path)
    end
  end


  def add_exercise(dest_name, options = {})
    options = {
      :commit => true,
      :fixture_name => 'SimpleExerciseWithSolutionsAndStubs'
    }.merge options
    local_clone.copy_fixture_exercise(options[:fixture_name], dest_name)
    local_clone.add_commit_push if options[:commit]
    local_clone
  end

  def delete_exercise(name)
    FileUtils.rm_rf "#{local_clone.path}/MyExercise"
    local_clone.add_commit_push
  end

  def change_course_metadata_file(data, options = {})
    change_metadata_file('course_options.yml', data, options)
  end

  def change_metadata_file(filename, data, options = {})
    options = { :raw => false, :commit => true }.merge options
    Dir.chdir local_clone.path do
      data = YAML.dump(data) unless options[:raw]
      File.open(filename, 'wb') {|f| f.write(data) }
      local_clone.add_commit_push if options[:commit]
    end
  end

end

