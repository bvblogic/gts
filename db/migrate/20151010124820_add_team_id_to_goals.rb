class AddTeamIdToGoals < ActiveRecord::Migration
  def change
    add_column :goals, :team_id, :integer
  end
end
