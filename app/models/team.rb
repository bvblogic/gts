class Team < ActiveRecord::Base
  has_many :team_users, dependent: :destroy
  has_many :users, through: :team_users
  has_many :goals
  belongs_to :manager, class_name: 'User', foreign_key: 'manager_id'

  validates_length_of :name, within: 3..45
  validates :name, :manager, presence: true
  validates :name, uniqueness: true

  scope :users_teams, ->(user) do
    case
    when user.admin?
      all
    when user.teams.any? 
      where('manager_id = ? OR team_users.user_id = ?', user.id, user.id)
      .joins(:team_users).includes(:team_users)
    when user.user? && user.team.present?
      joins(:team_users).where('team_users.user_id = ?', user.id)
      .includes(:team_users)
    else
      none
    end
  end

  scope :managed_teams, ->(user) do
    case
    when user.admin?
      all
    when user.teams.any? 
      where(manager_id: user.id).joins(:team_users).includes(:team_users)
    else
      none
    end
  end
  
  class << self
    # method for performing a search on teams index page
    def search(params, user)
      # creating an arel table
      table = Team.arel_table
      # basic collection for a following query
      relation = table[:id].in(Team.public_send(:users_teams, user).pluck(:id))
      exceptions = ['user_name', 'goal_id', 'created_at', 'updated_at']
      # making a query for allowed fields
      params.each do |key, value|
        next if value.blank? || exceptions.include?(key)
        relation = key == 'name' ? relation.and(table[:id].eq(value)) : relation.and(table[key].eq(value))
      end
      # making collection
      collection = Team.where(relation)
      # chaining exceptions if they are present
      collection = collection.where('DATE(teams.created_at) = ?', params[:created_at]) if params[:created_at].present?
      collection = collection.where('DATE(teams.updated_at) = ?', params[:updated_at]) if params[:updated_at].present?
      collection = collection.includes(:goals).where('goals.id' => params[:goal_id]) if params[:goal_id].present?
      collection = collection.includes(:users).where('users.name' => params[:user_name]) if params[:user_name].present?
      collection 
    end

    def batch(ids, user, action)
      teams = Team.where(id: ids)
      teams.each do |team|
        if action == 'delete'
          team.destroy if user.can? :destroy, team
        end
      end
    end
  end
end
