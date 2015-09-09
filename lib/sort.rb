module Sort
  def sort_team(params)
    sort_direction = %w[asc desc].include?(params[:direction]) ? params[:direction] : "asc"
    case params[:sort]
    when 'team_name'
      order('teams.name' + " " + sort_direction)
    when 'users'
      includes(:users).order('users.name' + " " + sort_direction)
    when 'manager'
      includes(:manager).order('users.name' + " " + sort_direction)
    when 'created_at'
      order('teams.created_at' + " " + sort_direction)
    else
      order('teams.created_at desc')
    end  
  end

  def sort_goal(params)
    sort_direction = %w[asc desc].include?(params[:direction]) ? params[:direction] : "asc"
    case params[:sort]
    when 'goal_name'
      order('goals.name' + " " + sort_direction)
    when 'description'
      order('description' + " " + sort_direction)
    when 'team' 
      includes(:team).order('teams.name' + " " + sort_direction)
    when 'status'
      order('status' + " " + sort_direction)
    when 'user'
      includes(:user).order('users.name' + " " + sort_direction)
    when 'start_date'
      order('start_date' + " " + sort_direction)
    when 'end_date'
      order('end_date' + " " + sort_direction)
    when 'image'
      order('goals.name' + " " + sort_direction)
    when 'progress'
      order('status' + " " + sort_direction)
    else
      order('goals.created_at desc')
    end

  end

end