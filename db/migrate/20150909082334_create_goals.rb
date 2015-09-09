class CreateGoals < ActiveRecord::Migration
  def change
    create_table :goals do |t|
      t.string :name
      t.integer :user_id
      t.text :description
      t.date :start_date
      t.date :end_date
      t.integer :status
      t.integer :parent_id

      t.timestamps null: false
    end
  end
end
