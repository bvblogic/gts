class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new 
    users_team_id = user.team.team_id if user.team
    subordinates = User.subordinates(user)
    managed_teams = User.managed_teams(user)
    case 
    when user.admin?
      can :create, Goal
      can [:destroy, :update], Goal, status: [Goal::OPEN, Goal::IN_PROGRESS, Goal::OUTDATED, nil], user_id: user.id
      can [:destroy, :update], Goal, user_id: user.id, is_template: true
      can [:new_template, :create_template, :create_from_template, :new_from_template], Goal
      can :manage, Category
      can :manage, Team
      can :read, :all
    when user.teams.any?
      can :create, Goal
      can :read, Goal, is_template: true
      can :read, Goal, status: [Goal::OPEN, Goal::CLOSED, Goal::IN_PROGRESS, Goal::OUTDATED, nil], user_id: user.id
      can :read, Goal, status: [Goal::OPEN, Goal::CLOSED, Goal::IN_PROGRESS, Goal::OUTDATED, nil], user_id: subordinates
      can :read, Goal, team_id: managed_teams, status: Goal::CLOSED
      can :read, Goal, team_id: users_team_id 
      can [:destroy, :read, :update], Goal, is_template: true, user_id: user.id
      can [:destroy, :read, :update], Goal, status: [Goal::OPEN, Goal::IN_PROGRESS, Goal::OUTDATED, nil], user_id: user.id, team_id: managed_teams
      can [:destroy, :read, :update], Goal, status: [Goal::OPEN, Goal::IN_PROGRESS, Goal::OUTDATED, nil], user_id: user.id
      can [:destroy, :read, :update], Goal, status: [Goal::OPEN, Goal::IN_PROGRESS, Goal::OUTDATED, nil], team_id: managed_teams
      can [:new_template, :create_template, :create_from_template, :new_from_template], Goal
      can [:read, :update], Team, manager_id: user.id
      can :read, Team, id: users_team_id
      cannot :manage, Category
    when user.user?
      can :create, Goal
      can :read, Goal, is_template: true
      can :read, Goal, status: Goal::CLOSED, user_id: user.id
      can :read, Goal, status: [Goal::OPEN, Goal::CLOSED, Goal::IN_PROGRESS, Goal::OUTDATED, nil], team_id: users_team_id
      can :read, Goal, status: [Goal::OPEN, Goal::CLOSED, Goal::IN_PROGRESS, Goal::OUTDATED, nil], team_id: users_team_id, is_template_based: true if user.team
      can [:destroy, :read, :update], Goal, status: [Goal::OPEN, Goal::IN_PROGRESS, Goal::OUTDATED, nil], user_id: user.id
      can [:create_from_template, :new_from_template], Goal
      can :read, Team, id: users_team_id
      cannot :read, Team if user.team.nil?
      cannot :manage, Category
    when user.role.nil?
      can :read, Goal, status: [Goal::OPEN, Goal::IN_PROGRESS], user_id: user.id
      cannot :manage, Category
      cannot :manage, Team
    end
  end
end
