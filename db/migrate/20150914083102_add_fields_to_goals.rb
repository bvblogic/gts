class AddFieldsToGoals < ActiveRecord::Migration
  def change
    add_column :goals, :is_template, :boolean, default: false
    add_column :goals, :is_template_based, :boolean, default: false
  end
end
