class TeamPresenter
  def initialize(team, template)
    @team = team
    @template = template
  end

  def h
    @template
  end

  def sortable(column, direction)
    column = column.parameterize.underscore
    unless column == 'users'
      h.link_to h.params.merge(sort: column, direction: direction) do
        h.render partial: direction == 'asc' ? '/goals/arrow_top' : '/goals/arrow_down'  
      end
    end
  end

  def team_name(team)
    h.link_to "#{team.name}", h.team_path(team), class:'link_goal_name'
  end

  def view(team)
    h.link_to I18n.t('view'), h.team_path(team) 
  end

  def delete(team)
    h.link_to I18n.t('delete'), h.team_path(team), method: :delete if h.can?(:destroy, team)
  end

  def team_goal_link(goal)
    h.link_to goal.name, h.goal_path(goal), class:'dl_link' 
  end

end