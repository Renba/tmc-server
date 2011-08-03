FactoryGirl.define do
  factory :user do
    sequence(:login) {|n| "user#{n}" }
    administrator false
  end

  factory :admin, :class => User do
    login 'admin'
    password 'adminpass'
    administrator true
  end
  
  factory :course, :class => Course do
    sequence(:name) {|n| "course#{n}" }
  end
  
  factory :exercise do
    course
    sequence(:name) {|n| "exercise#{n}" }
  end
  
  factory :submission do
    course
    user
    exercise
  end
  
  factory :test_case_run do
    sequence(:test_case_name) {|n| "test case #{n}" }
    submission
    successful false
  end
end