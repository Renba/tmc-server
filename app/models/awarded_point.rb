class AwardedPoint < ActiveRecord::Base
  belongs_to :course
  belongs_to :user
  belongs_to :submission

  validates_uniqueness_of :name, :scope => [:user_id, :submission_id]

  scope :course_user_points, lambda { |course, user|
    where(:course_id => course.id, :user_id => user.id)
  }

  scope :exercise_user_points, lambda { |exercise, user|
    where(:course_id => exercise.course_id, :user_id => user.id).
    joins(:submission).
    joins("join exercises on submissions.exercise_name = exercises.name").
    where(:exercises => { :name => exercise.name })
  }

  scope :course_user_sheet_points, lambda { |course, user, sheetname|
    course_user_points(course, user).
    joins(:submission).
    joins("join exercises on submissions.exercise_name = exercises.name").
    where("exercises.gdocs_sheet IS ?", sheetname)
  }

end
