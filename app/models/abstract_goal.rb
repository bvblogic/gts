class AbstractGoal < ActiveRecord::Base 
  self.abstract_class = true
  self.table_name = 'goals'

  belongs_to :user
  belongs_to :team

  delegate :name, to: :user, prefix: true, allow_nil: true
  delegate :name, to: :team, prefix: true, allow_nil: true
  
  validates      :name, :description, presence: true, length: 3..1024
  validates      :status, :start_date, :end_date, presence: true, 
                 unless: :parent_is_template?
  validates_date :start_date, on_or_after: lambda { Date.today }, on: :create, 
                  unless: :parent_is_template?
  validates_date :end_date, on_or_after: :start_date, 
                  unless: :parent_is_template?
  validates_date :start_date, on_or_after: :parent_start_date, 
                  unless: :parent_is_template?
  validates_date :end_date, on_or_before: :parent_end_date, 
                  unless: :parent_is_template?


  mount_uploader :image, PicturesUploader

  enum status: [:open, :in_progress, :closed_succ, :outdated]
  
  before_save :check_delete_image, :synchronize_status
  after_create :set_user_id, :set_team_id

  def self.status(object)
    if object.persisted? && !object.is_template
      @status = { 'Open' => :open, 'In progress' => :in_progress,
                 'Done!' => :closed_succ }
    else
      @status = { 'Open' => :open, 'In progress' => :in_progress }
    end
  end


  def self.table_headers
    [I18n.t('goal_name'), I18n.t('description'), I18n.t('team'), 
     I18n.t('status'), I18n.t('user'), I18n.t('start_date'), 
     I18n.t('end_date'), I18n.t('image'), I18n.t('progress')]
  end

  def parent_is_template?
    is_template || is_template_based 
  end

  def parent_start_date
    find_parent(self).start_date
  end

  def parent_end_date
    find_parent(self).end_date
  end

  private
  # if delete_image is true - it delete image and set delete_image to nil
  def check_delete_image
    remove_image! if delete_image
    delete_image = nil
  end
  # if goals end date expired - changes status to outdated
  def synchronize_status
    if end_date && end_date < Date.today
      status = 3 unless closed_succ?
    end
  end

  def set_user_id
    parent = find_parent(self)
    update_column(:user_id, parent.user_id)
  end

  def set_team_id
    parent = find_parent(self)
    update_column(:team_id, parent.team_id) if parent.team_id
  end
end
