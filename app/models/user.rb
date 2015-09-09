class User < ActiveRecord::Base
  devise :database_authenticatable, 
         :registerable, :recoverable, 
         :rememberable, :trackable, :validatable
  enum role: [:user, :admin]
  has_many :teams, foreign_key: 'manager_id'
  has_one :team, class_name: 'TeamUser'

  scope :subordinates, ->(user) { user.teams.includes(:team_users).pluck(:user_id) }
  scope :managed_teams, ->(user) { user.teams.pluck(:id) }

  default_scope -> { includes(:teams) }

  validates :name, presence: true, uniqueness: true
  # before_validation :get_ldap_email, :set_role, on: :create
  delegate :can?, :cannot?, to: :ability

  def ability
    @ability ||= Ability.new(self)
  end
  
  def get_ldap_email
    self.email = Devise::LDAP::Adapter.get_ldap_param(self.name,"mail").first
  end

  def set_role
    self.role = 0
  end

  class << self
    def collection
      { "User" => :user, "Admin" => :admin }
    end

    def user_with_manager(user)
      result = [user.id, Team.find_by(id: user.team.team_id).manager_id]
    end

    def subordinates_with_managers(user)
      subordinates = subordinates(user)
      subordinates << user.id 
      subordinates << nil
      if user.team.present?
        user_team_manager = Team.find_by(id: user.team.team_id).manager_id
        subordinates << user_team_manager
      end
      subordinates
    end
  end
end
