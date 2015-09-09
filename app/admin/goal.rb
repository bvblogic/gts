include Checkers::ProgressCounter
ActiveAdmin.register Goal do
  permit_params :status, :is_template, :name, :team_id, :description, 
  :start_date, :end_date, :parent_id, :image, :delete_image, 
  :user_id, category_ids: [], 
  sub_goals_attributes: [:id, :user_id, :parent_id, :_destroy, 
    :start_date, :end_date, :status, 
    :name, :image, :team_id, :description, :is_template, :delete_image, 
    sub_sub_goals_attributes: [:id, :parent_id, :user_id, :_destroy, :start_date, :end_date, 
      :status, :image, :name, :description, :is_template, :delete_image, :team_id]]

  collection_action :new_template, method: :get do
    @goal = Goal.new
    authorize! :new_template, @goal
  end

  collection_action :create_template, method: :post do
    @goal = Goal.new
    authorize! :create_template, @goal
    params[:goal][:user_id] = current_user.id
    @goal.attributes = permitted_params[:goal]
    if @goal.save
      flash[:success] = I18n.t('successfully_created')
      redirect_to goals_path
    else
      render :new_template, object: @goal
    end
  end

  member_action :new_from_template

  member_action :create_from_template, method: :patch do
    template_goal = Goal.find_by(id: params[:id])
    params[:goal][:user_id] = current_user.id
    template_goal.attributes = permitted_params[:goal]
    new_goal = template_goal.amoeba_dup
    new_goal.is_template = false
    new_goal.is_template_based = true
    if new_goal.save
      flash[:success] = I18n.t('successfully_created_from_template')
      redirect_to goals_path 
    else
      render :goal_from_template, object: @goal = template_goal
    end
  end

  member_action :close, method: :get do
    goal = Goal.find_by(id: params[:id])
    authorize! :update, goal
    goal.closed_succ!
    flash[:success] = I18n.t('goal_closed')
    redirect_to(:back)
  end

  member_action :add_substep, method: :get do
    @parent_id = Goal.find_by(id: params[:id]).id
    @goal = Goal.new
    respond_to do |format|
      format.js
    end
  end

  member_action :create_substep, method: :post do
    is_index_page = URI(request.referer).path == '/' || URI(request.referer).path == '/goals'
    params[:goal][:user_id] = current_user.id
    parent = Goal.find_by(id: params[:goal][:parent_id])
    params[:goal][:team_id] = parent.team_id if parent.team
    @goal = Goal.new(permitted_params[:goal])
    authorize! :update, parent
    if is_index_page
      @scoped_collection = scoped_collection.sort_goal(params)
      with_children = false
    else
      @scoped_collection = find_parent(parent).sub_goals.sort_goal(params)
      with_children = true
    end
    @goal.save
    render :create_substep, object: @goal, locals: { scoped_collection: 
            @scoped_collection, parent: parent, with_children: with_children }
  end

  collection_action :ajax_create_goal, method: :post do
    params[:goal][:user_id] = current_user.id
    @users_teams = Team.managed_teams(current_user)
    @goal = Goal.new(permitted_params[:goal])
    authorize! :create, @goal
    @scoped_collection = scoped_collection.order('created_at desc')
                        .page(params[:page]).per(15)
    @goal.save
    render :ajax_create_goal, object: @goal, 
            locals: { scoped_collection: @scoped_collection }
  end

  collection_action :custom_batch, method: :get do
    if params[:batch][:ids].blank?
      flash[:warning] = I18n.t('pls_select_values')
      redirect_to(:back)
    else
      ids = params[:batch][:ids].split(',').flatten
      Goal.batch(ids, current_user, params[:batch][:action_name])
      flash[:success] = I18n.t('action_performed')
      redirect_to(:back)
    end
  end

  controller do
    skip_before_action :verify_authenticity_token, only: [:destroy, :create, :create_substep, :ajax_create_goal]
    respond_to :html, :js
    layout 'custom_layout'
    def scoped_collection
      case 
      when current_user.admin?
        super.includes(:sub_goals).where(parent_id: nil, is_template: false, team_id: nil)
      when current_user.teams.any?
        super.includes(:sub_goals).where(parent_id: nil, is_template: false, team_id: nil, user_id: [current_user.id, User.subordinates(current_user)])
      when current_user.user?
        super.includes(:sub_goals).where(parent_id: nil, is_template: false, team_id: nil, user_id: current_user.id)
      end
    end

    def find_resource
      scoped_collection.unscope(:where).find(params[:id])
    end

    def new
      @parent_id = params[:parent]
      super
    end

    def create
      params[:goal][:user_id] = current_user.id
      parent_collection = Goal.find_by(id: params[:goal][:parent_id]) if params[:goal][:parent_id]
      params[:goal][:team_id] = parent_collection.team_id if parent_collection
      @scoped_collection = parent_collection.sub_goals.sort_goal(params) if parent_collection
      super
    end

    def show
      @table_headers = AbstractGoal.table_headers
      @goal = Goal.find_by(id: params[:id])
      if @goal.nil?
        flash[:error] = I18n.t('no_such_goal')
        redirect_to goals_path
      else
        @scoped_collection = @goal.sub_goals.any? ? @goal.sub_goals.sort_goal(params) : Goal.none
        @expand = params[:expand]
        @parent = @goal
        authorize! :show, @goal
        render 'show_custom'
      end
    end

    def edit
      @goal = Goal.find_by(id: params[:id])
      authorize! :edit, @goal
      render 'edit_custom'
    end

    def update
      @goal = Goal.find_by(id: params[:id])
      authorize! :update, @goal
      if @goal.update(permitted_params[:goal])
        flash[:notice] = I18n.t('successfully_updated')
        redirect_to goal_path(find_parent(@goal))
      else 
        render 'edit_custom', object: @goal
      end
    end

    def index 
      @archived_count = Goal.are_closed(current_user).count
      @all_count = scoped_collection.count
      @templates_count = Goal.is_templated_rows(current_user).count
      @team_goals_count = Goal.team_goals(current_user).count
      @team_archive_count = Goal.team_archive(current_user).count
      @categories = Category.all
      @users = User.all
      @users_teams = Team.managed_teams(current_user)
      @table_headers = AbstractGoal.table_headers
      @goal = Goal.new
      @scoped_collection = scoped_collection.sort_goal(params).page(params[:page]).per(15)
      @scoped_collection = Goal.public_send(params[:scope], current_user).sort_goal(params).page(params[:page]).per(15) if params[:scope].present?
      @scoped_collection = Goal.search(params[:search], current_user).sort_goal(params).page(params[:page]).per(15) if params[:search].present?
      render 'index_custom'
    end

    def new_from_template
      @goal = Goal.find_by(id: params[:id])
      @users_teams = Team.managed_teams(current_user)
      render :goal_from_template
    end
  end
end
