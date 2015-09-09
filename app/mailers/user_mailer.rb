class UserMailer < ApplicationMailer
  default from: "noreply-tgs@bvblogic.com"
  
  def user_reminder(user_id, goal)
    @user = User.find_by(id: user_id)
    @goal = goal
    @expiration_day = (@goal.end_date - Date.today).to_i
    mail(to: @user.email, subject: 'Tracking goals system reminder')
  end

  def manager_reminder(subordinated_user_id, users_goal)
    @goal = users_goal 
    @user = User.find_by(id: subordinated_user_id)
    @manager = find_manager(@user)
    @expiration_day = (@goal.end_date - Date.today).to_i
    mail(to: @manager.email, subject: 'Tracking goals system reminder') if @manager
  end

  def after_creation_user_email(goal)
    @goal = goal
    @user = User.find_by(id: @goal.user_id)
    mail(to: @user.email, subject: 'Goal has been successfully created')
  end

  def after_creation_manager_notification(goal)
    @goal = goal
    @user = User.find_by(id: @goal.user_id)
    @manager = find_manager(@user)
    mail(to: @manager.email, subject: 'Goal has been successfully created') if @manager
  end

  def email_for_users_goal_status_change(goal, old_status)
    @old_status = old_status
    @goal = goal
    @user = User.find_by(id: @goal.user_id)
    mail(to: @user.email, subject: 'Goal status was changed')
  end

  def email_for_users_manager_about_goal_status_change(goal, old_status)
    @old_status = old_status
    @goal = goal
    @user = User.find_by(id: @goal.user_id)
    @manager = find_manager(@user)
    mail(to: @manager.email, subject: 'Goal status was changed') if @manager 
  end


  def email_for_users_progress_change(old_progress, new_progress, goal)
    @old_progress = old_progress
    @new_progress = new_progress
    @goal = goal
    @user = User.find_by(id: @goal.user_id)
    mail(to: @user.email, subject: 'Progress on a goal')
  end

  def manager_notification_about_users_progress_change(old_progress, new_progress, goal)
    @old_progress = old_progress
    @new_progress = new_progress
    @goal = goal
    @user = User.find_by(id: @goal.user_id)
    @manager = find_manager(@user)
    mail(to: @manager.email, subject: 'Progress on a goal') if @manager 
  end

  def find_manager(user)
    user_team = Team.find_by(id: user.team.team_id) if user.team.present?
    manager = User.find_by(id: user_team.manager_id) if user_team
    manager
  end
end
