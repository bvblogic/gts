class SubGoal < AbstractGoal
  has_many :sub_sub_goals, class_name: 'SubSubGoal', foreign_key: 'parent_id', dependent: :delete_all 

  accepts_nested_attributes_for :sub_sub_goals, reject_if: :all_blank, allow_destroy: true 

  # amoeba is a gem to duplicate onjects with relations and nested attributes
  # used here to create a goa's subgoal from template
  amoeba do
    enable
    customize(lambda { |original_goal,new_goal|
        new_goal.image = original_goal.image
        new_goal.is_template = false
        new_goal.is_template_based = true
        })
  end
end
