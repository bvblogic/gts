class AddManagerIdInTeam < ActiveRecord::Migration
  def change
    add_reference :teams, :manager, index: true
  end
end
