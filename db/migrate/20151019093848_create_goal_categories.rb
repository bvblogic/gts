class CreateGoalCategories < ActiveRecord::Migration
  def change
    create_table :goal_categories do |t|
      t.integer :goal_id
      t.integer :category_id

      t.timestamps null: false
    end
  end
end
