class GoalCategory < ActiveRecord::Base
  belongs_to :goal
  belongs_to :category 
end
