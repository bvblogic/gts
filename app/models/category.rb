class Category < ActiveRecord::Base
  has_many :goal_categories 
  has_many :goals, through: :goal_categories

  validates :name, presence: true, uniqueness: true
end
