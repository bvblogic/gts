class AddImageToGoal < ActiveRecord::Migration
  def change
    add_column :goals, :image, :string, after: :status
  end
end
