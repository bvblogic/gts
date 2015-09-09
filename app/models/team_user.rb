class TeamUser < ActiveRecord::Base
  belongs_to :user
  belongs_to :team
  enum role: [:team_lead]
end
