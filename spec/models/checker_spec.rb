require 'rails_helper'

RSpec.describe Checkers do
  let(:including_class) { Class.new { include Checkers::StatusChecker } }
  
  describe 'find_parent method' do
    it 'is expected to return parent goal if have parent' do
      parent = create(:goal, name: 'Foo')
      child = create(:goal, parent_id: parent.id)
      expect(including_class.find_parent(child)).to eq(parent)
    end
    it 'is expected to return parent goal if have no parent' do
      parent = create(:goal)
      expect(including_class.find_parent(parent)).to eq(parent)
    end
  end
  describe 'check method' do
    it 'is expected to change goal status to in progress if any of its subgoals have status in progress, outdated or done' do
      goal = create(:goal, status: 0)
      subgoal = create(:goal, status: 1, parent_id: goal.id)
      including_class.check(goal)
      expect(goal.status).to eq('in_progress')
    end
    it 'is expected to change goal status to in progress if any of its subsubgoals have status in progress, outdated or done' do
      goal = create(:goal, status: 0)
      subgoal = create(:goal, status: 0, parent_id: goal.id)
      subsubgoal = create(:goal, status: 1, parent_id: subgoal.id)
      including_class.check(goal)
      expect(goal.status).to eq('in_progress')
    end
    it 'is expected to change subgoal status to in progress if any of its subsubgoals have status in progress, outdated or done' do
      goal = create(:goal, status: 0)
      subgoal = create(:goal, status: 0, parent_id: goal.id)
      subsubgoal = create(:goal, status: 1, parent_id: subgoal.id)
      including_class.check(goal)
      subgoal.reload
      expect(subgoal.status).to eq('in_progress')
    end
    it 'is expected to change goal status to done if all of its subgoals have status done' do
      goal = create(:goal, status: 0)
      subgoal = create(:goal, status: 2, parent_id: goal.id)
      including_class.check(goal)
      expect(goal.status).to eq('closed_succ')
    end
    it 'is expected to change subgoal status to done if all of its subsubgoals have status done' do
      goal = create(:goal, status: 0)
      subgoal = create(:goal, status: 0, parent_id: goal.id)
      subsubgoal = create(:goal, status: 2, parent_id: subgoal.id)
      including_class.check(goal)
      subgoal.reload
      expect(subgoal.status).to eq('closed_succ')
    end 
    it 'is expected not to change goals status to done if any of his subgoals have status open, in progress or outdated' do
      goal = create(:goal, status: 0)
      subgoal1 = create(:goal, status: 1, parent_id: goal.id)
      subgoal2 = create(:goal, status: 3, parent_id: goal.id)
      subgoal3 = create(:goal, status: 2, parent_id: goal.id)
      including_class.check(goal)
      expect(goal.status).not_to eq('closed_succ')
    end
    it 'is expected not to change subgoals status to done if any of his subsubgoals have status open, in progress or outdated' do
      goal = create(:goal, status: 0)
      subgoal = create(:goal, status: 1, parent_id: goal.id)
      subsubgoal1 = create(:goal, status: 3, parent_id: subgoal.id)
      subsubgoal2 = create(:goal, status: 1, parent_id: subgoal.id)
      subsubgoal3 = create(:goal, status: 2, parent_id: subgoal.id)
      including_class.check(goal)
      subgoal.reload
      expect(subgoal.status).not_to eq('closed_succ')
    end
  end
  describe 'count_whole_progress method' do
    let(:klass) { Class.new { include Checkers::ProgressCounter } }
    let(:parent) { create(:goal) }
    it 'is expected to return a percentage of closed subgoals' do
      child1 = create(:goal, parent_id: parent.id, status: 2)
      child2 = create(:goal, parent_id: parent.id, status: 0)
      child3 = create(:goal, parent_id: parent.id, status: 2)
      child3 = create(:goal, parent_id: parent.id, status: 1)
      expect(klass.count_whole_progress(parent)).to eq(50)
    end
    it 'is expected to include closed subsubgoals' do
      child1 = create(:goal, parent_id: parent.id, status: 1)
      grandchild1 = create(:goal, parent_id: child1.id, status: 2)
      grandchild2 = create(:goal, parent_id: child1.id, status: 0)
      child2 = create(:goal, parent_id: parent.id, status: 0)
      grandchild3 = create(:goal, parent_id: child2.id, status: 2)
      grandchild4 = create(:goal, parent_id: child2.id, status: 3)
      expect(klass.count_whole_progress(parent)).to eq(33)
    end
    it 'is expected to return zero if goal have no closed subgoals' do
      child1 = create(:goal, parent_id: parent.id, status: 3)
      child2 = create(:goal, parent_id: parent.id, status: 0)
      expect(klass.count_whole_progress(parent)).to eq(0)
    end
  end
  describe 'progress? method' do
    let(:klass) { Class.new { include Checkers::ProgressCounter } }
    let(:parent) { create(:goal) }
    it 'is expected to count percentage of closed steps for a given goal' do
      child = create(:goal, parent_id: parent.id, status: 1)
      child1 = create(:goal, parent_id: parent.id, status: 2)
      child2 = create(:goal, parent_id: parent.id, status: 3)
      child3 = create(:goal, parent_id: parent.id, status: 2)
      expect(klass.progress?(parent)).to eq(50)
    end
    it 'is expected not to count "grandchildren", only direct posterity' do
      child = create(:goal, parent_id: parent.id, status: 1)
      grandchild = create(:goal, parent_id: child.id, status: 0)
      grandchild2 = create(:goal, parent_id: child.id, status: 2)
      expect(klass.progress?(parent)).to eq(0)
    end
  end
end