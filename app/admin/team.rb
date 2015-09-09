include Sort
ActiveAdmin.register Team do
  permit_params :name, :manager_id, user_ids: []
  before_filter :check_if_have_team, only: :index

  collection_action :custom_batch, method: :get do
    if params[:batch][:ids].blank?
      flash[:warning] = I18n.t('pls_select_values')
      redirect_to(:back)
    else
      ids = params[:batch][:ids].split(',').flatten
      Team.batch(ids, current_user, params[:batch][:action_name])
      flash[:success] = I18n.t('action_performed')
      redirect_to(:back)
    end
  end

  controller do
    skip_before_action :verify_authenticity_token, only: [:destroy, :create]
    respond_to :html, :js
    layout 'custom_layout'

    def index
      @team = Team.new
      @users = User.all.includes(:team)
      teams_users = @users.joins(:team).pluck(:id)
      @form_users = User.where.not(id: teams_users)
      manager_ids = Team.all.pluck(:manager_id)
      @managers = User.where(id: manager_ids)
      @goals = Goal.where.not(team_id: nil).where(parent_id: nil)
      @teams = Team.all
      @column_names = ['Team name', 'Users', 'Manager', 'Created at']
      @scoped_collection = Team.public_send(:users_teams, current_user).sort_team(params)
      @scoped_collection = Team.search(params[:search], current_user).sort_team(params) if params[:search].present?
      render 'custom_index'
    end

    def show
      @team = Team.find_by(id: params[:id])
      authorize! :show, @team
      render 'custom_show'
    end

    def edit
      @team = Team.find_by(id: params[:id])
      authorize! :edit, @team
      @users = User.select(:id, :name)
      teams_users = @users.joins(:team).pluck(:id)
      @no_team_users = User.where.not(id: teams_users)
      @no_team_users += User.where(id: @team.user_ids)
      render 'custom_edit'
    end

    def update
      @team = Team.find_by(id: params[:id])
      authorize! :update, @team
      if @team.update(permitted_params[:team])
        flash[:success] = I18n.t('successfully_updated')
        redirect_to team_path(@team)
      else 
        @users = User.select(:id, :name)
        teams_users = @users.joins(:team).pluck(:id)
        @no_team_users = User.where.not(id: teams_users)
        @no_team_users += User.where(id: @team.user_ids)
        render 'custom_edit', object: @team
      end
    end

    def create
      @users = User.all.includes(:team)
      teams_users = @users.joins(:team).pluck(:id)
      teams_users += params[:team][:user_ids].reject!(&:blank?)
      @form_users = User.where.not(id: teams_users)
      @scoped_collection = Team.public_send(:users_teams, current_user).sort_team(params)
      super
    end

    private

    def check_if_have_team
      redirect_to goals_path if current_user.team.blank? && current_user.teams.blank? && !current_user.admin?
    end
  end
end
