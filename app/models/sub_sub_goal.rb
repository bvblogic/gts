class SubSubGoal < AbstractGoal
  belongs_to :parent_goal, class_name: 'SubGoal', foreign_key: 'parent_id'
  # amoeba is a gem to duplicate onjects with relations and nested attributes
  # used here to create a goal's sub sub goal from template
  amoeba do
    enable
    customize(lambda { |original_goal,new_goal|
        new_goal.image = original_goal.image
        new_goal.is_template = false
        new_goal.is_template_based = true
        })
  end

end
