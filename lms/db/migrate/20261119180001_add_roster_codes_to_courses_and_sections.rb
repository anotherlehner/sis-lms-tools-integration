class AddRosterCodesToCoursesAndSections < ActiveRecord::Migration[7.1]
  def change
    add_column :courses, :course_code, :string
    add_column :sections, :class_code, :string
  end
end
