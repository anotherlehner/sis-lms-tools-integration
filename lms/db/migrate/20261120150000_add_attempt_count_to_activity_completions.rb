class AddAttemptCountToActivityCompletions < ActiveRecord::Migration[7.1]
  def change
    add_column :activity_completions, :attempt_count, :integer
    add_check_constraint :activity_completions, "attempt_count IS NULL OR attempt_count > 0",
      name: "activity_completion_attempt_count_valid"
  end
end
