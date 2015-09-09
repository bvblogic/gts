include Checkers::StatusChecker
class Goal < AbstractGoal
  OPEN = 'open'
  IN_PROGRESS = 'in_progress'
  CLOSED = 'closed_succ'
  OUTDATED = 'outdated'

  has_many :sub_goals, class_name: 'SubGoal', foreign_key: 'parent_id', dependent: :delete_all 
  has_many :goal_categories
  has_many :categories, through: :goal_categories
  
  accepts_nested_attributes_for :sub_goals, reject_if: :all_blank, allow_destroy: true

  validates :category_ids, presence: true, unless: :is_template_based?

  scope :default_queue, -> { where(parent_id: nil, is_template: false, team_id: nil)
    .includes(:sub_goals) }
  scope :belongs_to_team, -> { joins(:sub_goals) }
  scope :is_templated_rows, ->(user) { where(is_template: true).where(parent_id: nil)
    .includes(:sub_goals) }
  scope :are_closed, ->(user) { where(user_id: user.id).where(status: "2")
    .where(team_id: nil, parent_id: nil) }
  scope :team_goals, ->(user) do 
    case 
    when user.admin?
      where(status: ["0", "1"], parent_id: nil).where.not(team_id: nil)
    when user.teams.any? && user.team.present?
      where('user_id = ? OR team_id = ? OR team_id IN (?)', 
      user.id, user.team.team_id, user.teams.pluck(:id))
      .where(status: ["0", "1"], parent_id: nil).where.not(team_id: nil)
    when user.teams.any?
      where('user_id = ? OR team_id IN (?)', user.id, user.teams.pluck(:id))
      .where(status: ["0", "1"], parent_id: nil).where.not(team_id: nil)
    when user.user? && user.team.present?
      where(team_id: user.team.team_id, status: ['0','1'], parent_id: nil)
      .includes(:sub_goals)
    else
      none
    end
  end
  scope :team_archive, ->(user) do
    case
    when user.admin?
      where(status: "2", parent_id: nil).where.not(team_id: nil)
    when user.teams.any? && user.team.present?
      where('user_id = ? OR team_id = ? OR team_id IN (?)', 
      user.id, user.team.team_id, user.teams.pluck(:id))
      .where(status: "2", parent_id: nil).where.not(team_id: nil)
    when user.teams.any?
      where('user_id = ? OR team_id IN (?)', user.id, user.teams.pluck(:id))
      .where(status: "2", parent_id: nil).where.not(team_id: nil) 
    when user.user? && user.team.present?
      where(team_id: user.team.team_id, status: "2", parent_id: nil)
      .includes(:sub_goals)
    else
      none
    end
  end
 
  before_update :check_old_progress
  after_update  :send_email_if_progress_changed
  after_save    :check_and_update_goal
  after_save    :send_email_if_status_changed
  after_create  :send_email_about_creation, unless: :have_parent 

  # amoeba is a gem to duplicate objects with relations and nested attributes
  # used here to create a goal from template
  amoeba do
    enable
    customize(lambda { |original_goal,new_goal|
      new_goal.image = original_goal.image
      new_goal.is_template = false
      new_goal.is_template_based = true
    })
  end

  def is_template_based?
    is_template_based && new_record? || parent_id?
  end

  def have_parent
    parent_id?
  end

  class << self 
    def search(params, user)
      goal_arel_table = Goal.arel_table
      case 
      when user.admin?
        relation = goal_arel_table[:parent_id].eq(nil)
      when user.teams.any?
        relation = goal_arel_table[:user_id].in(User.subordinates_with_managers(user))
          .or(goal_arel_table[:is_template].eq(true))
          .and(goal_arel_table[:parent_id].eq(nil)) 
      when user.user? && user.team && ['team_goals', 'team_archive'].include?(params[:scope].to_s) 
        relation = goal_arel_table[:user_id].in(User.user_with_manager(user))
          .or(goal_arel_table[:is_template].eq(true))
          .and(goal_arel_table[:parent_id].eq(nil))
      when user.user? 
        relation = goal_arel_table[:user_id].eq(user.id)
          .or(goal_arel_table[:is_template].eq(true))
          .and(goal_arel_table[:parent_id].eq(nil))
      end
      params.each do |key, value|
        next if value.blank? || key == 'category_id'
        relation = relation.and(goal_arel_table[key].matches("%#{value}%")) if key == 'name'
        relation = relation.and(goal_arel_table[key].eq(value)) if key == 'start_date' || key == 'end_date'
        relation = relation.and(goal_arel_table[key].eq(value)) if key == 'team_id' || key == 'user_id'
      end
      collection = params[:scope].blank? ? Goal.where(relation) : Goal.public_send(params[:scope], user).where(relation)
      collection = collection.includes(:categories).where('categories.id' => params[:category_id]) if params[:category_id].present?
      collection
    end

    # method for a batch action
    def batch(ids, user, action)
      goals = Goal.where(id: ids)
      goals.each do |goal|
        if action == 'delete'
          goal.destroy if user.can? :destroy, goal
        end
        if action == 'archive'
          goal.closed_succ! if user.can? :update, goal
        end
      end
    end

    # creates a list of goals users need to be reminded of
    # runs sender method to send email-reminder
    def mail_reminder
      month_date = Date.today + 30.days
      week_date = Date.today + 7.days
      goals_to_remind = Goal.where(status: ["0","1"], 
                                   end_date: [month_date, week_date, Date.tomorrow])
                            .limit(1000)
      goals_to_remind.each do |goal|
        Goal.sender(goal)
      end
    end

    # sends out emails about deadlines on goals
    def sender(goal)
      parent = find_parent(goal)
      UserMailer.user_reminder(parent.user_id, goal).deliver_now
      UserMailer.manager_reminder(parent.user_id, goal).deliver_now
    end
  end


private
  
  # it updates goals status depending on it's date and sub goals statuses
  # also checks primary goal's old status and writes it in the @parent_old_status variable
  def check_and_update_goal
    check(self)
  end

  # runs the method that counts progress on a certain goal before the update
  # and remembers it for further comparsion 
  def check_old_progress
    goal = find_parent(self) 
    @old_progress = count_whole_progress(goal)
  end

  # recounts progress on a certain goal after update
  # and if its different - sends email about the changes to user
  def send_email_if_progress_changed
    goal = find_parent(self)
    new_progress = count_whole_progress(goal)
    UserMailer.email_for_users_progress_change(@old_progress, new_progress, goal)
      .deliver_now if new_progress != @old_progress && new_progress > 0
    UserMailer.manager_notification_about_users_progress_change(@old_progress, new_progress, goal)
      .deliver_now if new_progress != @old_progress && new_progress > 0
  end

  # checks primary goal's old status(it is stored in the @parent_old_status variable)
  # and compares it to the new one
  # if they are different - sends user notification about the change
  def send_email_if_status_changed
    goal = find_parent(self)
    UserMailer.email_for_users_goal_status_change(goal, @parent_old_status)
      .deliver_now if @parent_old_status && @parent_old_status != goal.status
    UserMailer.email_for_users_manager_about_goal_status_change(goal, @parent_old_status)
      .deliver_now if @parent_old_status && @parent_old_status != goal.status
  end

  # sends user a notification about a newly created goal
  def send_email_about_creation
    UserMailer.after_creation_user_email(self).deliver_now unless self.is_template
    UserMailer.after_creation_manager_notification(self).deliver_now unless self.is_template
  end
end
