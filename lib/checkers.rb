module Checkers
  module StatusChecker
    def check(goal)
      date_status_checker(goal)
      unless check_if_has_parent(goal)
        @parent_old_status = goal.status_was
        status_changer(goal)
      end
    end

    def find_parent(goal)
      while goal.parent_id do 
      goal = Goal.find_by(id: goal.parent_id)
      end
      goal
    end
 
    def date_status_checker(goal)
      status_changer(goal) if goal.parent_id
      steps_checker(goal.sub_goals, goal) if goal.sub_goals.any?
    end

    def steps_checker(steps, goal)
      steps.each do |step|
        status_changer(step) if goal.parent_id.blank?
      end
    end

    def check_if_has_parent(goal)
      if goal.parent_id 
        parent = Goal.find_by(id: goal.parent_id)
        @parent_old_status = parent.status
        status_changer(parent)
        check_if_has_parent(parent)
      else
        false
      end
    end

    def status_changer(goal)
      temp = goal.sub_sub_goals unless goal.try(:sub_sub_goals).nil?
      temp = goal.sub_goals unless goal.try(:sub_goals).nil?
      goal.update_column(:status, 1) if temp.where(status: [1,2,3]).any?
      goal.update_column(:status, 2) if temp.count == temp.where(status: 2).count && temp.any?
    end
  end

  module ProgressCounter
    def progress?(goal)
      t = ProgressCheck.new
      t.check_count(goal)
      unless goal.is_template
        t.check_steps_progress(goal)
      end
    end

    def count_whole_progress(goal)
      all_goals = goal.sub_goals.count
      closed_goals = goal.sub_goals.where(status: "2").count
      goal.sub_goals.each do |step|
        all_goals += step.sub_sub_goals.count
        closed_goals += step.sub_sub_goals.where(status: "2").count
      end
      if closed_goals == 0
        whole_progress = 0
      else
        whole_progress = (100*closed_goals)/all_goals
        whole_progress.round
      end 
    end

    class ProgressCheck
      def check_steps_progress(goal)
        if goal.closed_succ?
          progress = 100
        elsif @count >= 1
          progress = (100*@closed_count)/@count
          progress.round
        else
          progress = 0
        end
      end

      def check_count(goal)
        if goal.parent_id && goal.class.name == 'SubGoal'
          @count = goal.sub_sub_goals.count
          @closed_count = goal.sub_sub_goals.where(status: "2").count
        else
          @count = goal.sub_goals.count
          @closed_count = goal.sub_goals.where(status: "2").count
        end
      end
    end
  end
end
