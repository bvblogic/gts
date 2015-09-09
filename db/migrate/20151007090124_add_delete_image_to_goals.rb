class AddDeleteImageToGoals < ActiveRecord::Migration
  def change
    add_column :goals, :delete_image, :boolean
  end
end
