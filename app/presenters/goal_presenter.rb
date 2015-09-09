class GoalPresenter
  def initialize(goal, template)
    @goal = goal
    @template = template
  end

  def h
    @template
  end

  def template_button
    h.link_to I18n.t('new_template'), h.new_template_goals_path, class: "btn btn_default pull-right btn_in_title" if h.current_user.admin? || h.current_user.teams.any?
  end

  def sortable(column, direction)
    exceptions = %w(image progress)
    column = column.parameterize.underscore
    unless exceptions.include?(column)
      h.link_to h.params.merge(sort: column, direction: direction) do
        h.render partial: direction == 'asc' ? 'arrow_top' : 'arrow_down'  
      end
    end
  end

  def view(goal=@goal)
    h.link_to I18n.t('view'), h.goal_path(goal) if h.can? :read, find_parent(goal)
  end

  def copy(goal=@goal)
    h.link_to I18n.t('copy'), h.new_from_template_goal_path(goal) if goal.is_template && !goal.parent_id
  end

  def delete(goal=@goal)
    if h.can? :destroy, find_parent(goal)
      h.link_to I18n.t('delete_goal'), h.goal_path(goal), method: :delete, confirm: "Are you sure?" unless goal.closed_succ?
    end
  end

  def archive(goal=@goal)
    if goal.open? || goal.in_progress? 
      h.link_to I18n.t('archive'), h.close_goal_path(goal) if goal.user_id == h.current_user.id
    end
  end

  def add_step(goal=@goal)
    unless goal.parent_id.present? && find_parent(goal).id != goal.parent_id 
      h.link_to I18n.t('add_step'), h.add_substep_goal_path(goal), remote: true if h.can? :update, find_parent(goal)
    end
  end

  def edit(goal=@goal)
    h.link_to I18n.t('edit_goal'), h.edit_goal_path(goal) if h.can? :update, find_parent(goal)
  end

  def span_field(goal=@goal)
    if goal.team_id 
      h.content_tag(:span, I18n.t('team'), class: "label label_team")
    elsif goal.is_template 
      h.content_tag(:span, I18n.t('template'), class: "label label_tpl")
    else 
      h.content_tag(:span, I18n.t('person'), class: "label label_person")
    end 
  end

  def goal_name_link(goal=@goal)
    h.link_to "#{goal.name}", h.goal_path(goal), class:'link_goal_name'
  end

  def goal_description_link(goal=@goal)
    h.link_to "#{goal.description}", h.goal_path(goal), class:'link_description'
  end

  def status(goal=@goal)
    if goal.status
      goal.closed_succ? ? I18n.t('done') : goal.status.humanize
    end
  end

  def expand_button
    if h.request.fullpath.include? 'expand=true'
      h.link_to(I18n.t('collapse_all'), nil, { class:'show_link pull-right' }) 
    else
      h.link_to(I18n.t('expand_all'), { expand: true }, { class:'show_link pull-right' })
    end
  end

  def add_step_button(goal) 
    if goal.parent_id.present? && find_parent(goal).id == goal.parent_id && h.can?(:update, find_parent(goal))
      h.link_to I18n.t('add_step'), h.new_goal_path(parent: goal), remote: true, class:"btn btn_primary pull-right btn_same_width", disabled: goal.is_template_based 
    elsif goal.parent_id.blank? && h.can?(:update, find_parent(goal))
      h.link_to I18n.t('add_step'), h.new_goal_path(parent: goal), remote: true, class:"btn btn_primary pull-right btn_same_width", disabled: goal.is_template_based
    else
      h.link_to I18n.t('add_step'), h.new_goal_path(parent: goal), remote: true, class:"btn btn_primary pull-right btn_same_width disabled"
    end
  end
end