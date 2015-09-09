require 'rails_helper'
require "cancan/matchers"

RSpec.describe Goal, type: :model do
  describe 'Abstract goal' do
    describe 'Associations' do
      it { is_expected.to belong_to(:user) }
      it { is_expected.to belong_to(:team) }
    end
    describe 'Validations' do
      it 'is invalid without a name' do
        goal = Goal.new(name: nil)
        goal.valid?
        expect(goal.errors[:name]).to include("can't be blank")
      end
      it 'is invalid without description' do
        goal = Goal.new(description: nil)
        goal.valid?
        expect(goal.errors[:description]).to include("can't be blank") 
      end
      it 'is not validating status, start date, end date if is template' do
        goal = Goal.new(is_template: true,
                        status: nil,
                        start_date: nil,
                        end_date: nil)
        goal.valid?
        expect(goal.errors.keys).not_to include(:status, :start_date, :end_date)
      end
      it 'is not validating status, start date, end date if is template based' do
        goal = Goal.new(is_template_based: true,
                        status: nil,
                        start_date: nil,
                        end_date: nil)
        goal.valid?
        expect(goal.errors.keys).not_to include(:status, :start_date, :end_date)
      end
      it 'is validating status, start date, end date if is not template' do
        goal = Goal.new(is_template: false,
                        status: nil,
                        start_date: nil,
                        end_date: nil)
        goal.valid?
        expect(goal.errors.keys).to include(:status, :start_date, :end_date)
      end
      it 'is validating status, start date, end date if is not template based' do
        goal = Goal.new(is_template_based: false,
                        status: nil,
                        start_date: nil,
                        end_date: nil)
        goal.valid?
        expect(goal.errors.keys).to include(:status, :start_date, :end_date)
      end
      it 'is validating start date on creation if is not template' do
        goal = Goal.new(is_template: false,
                        start_date: nil)
        goal.valid?
        expect(goal.errors[:start_date]).to include("is not a valid date")
      end
      it 'is validating start date to be equal to todays day if is not template' do
        goal = Goal.new(is_template: false,
                        start_date: Date.yesterday)
        goal.valid?
        expect(goal.errors[:start_date]).to include("must be on or after #{Date.today}")
      end
      it 'is not validating start date if is template' do
        goal = Goal.new(is_template: true,
                        start_date: nil)
        goal.valid?
        expect(goal.errors[:start_date]).to be_empty
      end
      it 'is not validating start date if is updating template' do
        goal = create(:goal, is_template: true)
        goal.start_date = nil
        goal.valid?
        expect(goal.errors[:start_date]).to be_empty
      end
      it 'is validating end date to be on or after start date' do
        goal = build(:goal, start_date: Date.today, end_date: Date.yesterday)
        goal.valid?
        expect(goal.errors[:end_date]).to include("must be on or after #{Date.today}")
      end
      it 'is validating start date to be on or after parents start date' do
        parent = create(:goal, start_date: Date.today)
        child = build(:goal, parent_id: parent.id, start_date: Date.yesterday)
        child.valid?
        expect(child.errors[:start_date]).to include("must be on or after #{Date.today}")
      end
      it 'is valid if start date is on or after parents start date' do
        parent = create(:goal, start_date: Date.today)
        child = build(:goal, parent_id: parent.id, start_date: Date.tomorrow)
        expect(child).to be_valid
      end
      it 'is valid if end date is on or before parents end date' do
        parent = create(:goal, end_date: 10.days.from_now)
        child = build(:goal, parent_id: parent.id, end_date: 9.days.from_now)
        expect(child).to be_valid
      end
      it 'is invalid if end date is after parents end date' do
        parent = create(:goal, end_date: 10.days.from_now)
        child = build(:goal, parent_id: parent.id, end_date: 20.days.from_now)
        expect(child).not_to be_valid
      end
    end
    describe 'Class methods' do
      context 'status' do
        it 'returns hash without key Done! if is new goal and not template' do
          goal = build(:goal)
          expect(Goal.status(goal)).not_to have_key("Done!")
        end
        it 'returns hash with key Done! if is persisted goal and not template' do
          goal = create(:goal, is_template: false)
          expect(Goal.status(goal)).to have_key("Done!")
        end
        it 'returns hash without key Done! if is persisted goal and template' do
          goal = create(:goal, is_template: true)
          expect(Goal.status(goal)).not_to have_key("Done!")
        end
        it 'returns hash without key Done! if is not persisted object and not template' do
          goal = build(:goal, is_template: false)
          expect(Goal.status(goal)).not_to have_key("Done!")
        end
      end
      context 'table_headers' do
        it 'returns an array' do
          expect(Goal.table_headers).to be_an_instance_of(Array) 
        end
        it 'is not empty' do
          expect(Goal.table_headers).not_to be_empty
        end
      end
      context 'parent_is_template?' do
        it 'returns true if goal is template' do
          goal = build(:goal, is_template: true)
          expect(goal.parent_is_template?).to be true
        end
        it 'returns true if goal is template based' do
          goal = build(:goal, is_template_based: true)
          expect(goal.parent_is_template?).to be true
        end
        it 'returns false if goal is not template' do
          goal = build(:goal, is_template: false)
          expect(goal.parent_is_template?).to be_falsy
        end
        it 'returns false if goal is not template based' do
          goal = build(:goal, is_template_based: false)
          expect(goal.parent_is_template?).to be_falsy
        end
      end
      context 'parent_start_date' do
        it 'returns parents start date' do
          parent = create(:goal)
          child = build(:goal, parent_id: parent.id)
          expect(child.parent_start_date).to eq(parent.start_date)
        end
        it 'returns self start date if has no parent' do
          child = build(:goal, parent_id: nil)
          expect(child.parent_start_date).to eq(child.start_date)
        end
      end
      context 'parent_end_date' do
        it 'returns parents end date' do
          parent = create(:goal)
          child = build(:goal, parent_id: parent.id)
          expect(child.parent_end_date).to eq(parent.end_date)
        end
        it 'returns self end date if has no parent' do
          child = build(:goal, parent_id: nil)
          expect(child.parent_end_date).to eq(child.end_date)
        end
      end
    end
  end
  describe 'Goal' do
    describe 'Associations' do
      it { is_expected.to have_many(:sub_goals) }
      it { is_expected.to have_many(:goal_categories) }
      it { is_expected.to have_many(:categories) }
      it { is_expected.to accept_nested_attributes_for(:sub_goals) }
    end
    describe 'Validations' do
      it 'is expected to be invalid without categories' do
        goal = Goal.new(category_ids: nil)
        goal.valid?
        expect(goal.errors[:category_ids]).to include("can't be blank")
      end
      it 'is expected not to validate presence of category ids if goal is template based and new record' do
        goal = Goal.new(category_ids: nil,
                        is_template_based: true)
        goal.valid?
        expect(goal.errors[:category_ids]).to be_empty
      end
      it 'is expected not to validate presence of category ids if is child' do
        parent = create(:goal)
        child = build(:goal, parent_id: parent.id, category_ids:nil)
        child.valid?
        expect(child.errors[:category_ids]).to be_empty
      end
      it 'is expected to validate presence of category ids if goal is persisted' do
        goal = create(:goal)
        goal.category_ids = nil
        goal.valid?
        expect(goal.errors[:category_ids]).to include("can't be blank")
      end
    end
    describe 'Scopes' do
      let!(:user) { create(:user) }
      context 'default_queue' do
        it 'is expected to return goals with no parents' do
          goal = create(:goal, team_id: nil, parent_id: nil)
          expect(Goal.default_queue).to include(goal)
        end
        it 'is expected to return query of goals without children' do
          goal = create(:goal, team_id: nil)
          child = create(:goal, parent_id: goal.id, team_id: nil)
          child2 = create(:goal, parent_id: goal.id, team_id: nil)
          child3 = create(:goal, parent_id: goal.id, team_id: nil)
          expect(Goal.default_queue).not_to match_array([child, child2, child3])      
        end
        it 'is expected to return query of goals without templates' do
          goals = create_list(:goal, 5)
          template = create(:goal, is_template: true, team_id: nil)
          expect(Goal.default_queue).not_to include(template)
        end
        it 'is expected to return query of goals that are not for a team' do
          goals = create_list(:goal, 5)
          team = create(:team)
          team_goal = create(:goal, team_id: team.id)
          expect(Goal.default_queue).not_to include(team_goal)
        end
      end
      context 'is_templated_rows' do
        it 'is expected to return query of goals that are templates' do
          goals = create_list(:goal, 3)
          template1 = create(:goal, is_template: true)
          template2 = create(:goal, is_template: true)
          expect(Goal.is_templated_rows(user)).to match_array([template1, template2])
        end
        it 'is expected to return query of templates that are not children' do
          parent = create(:goal)
          goals = create_list(:goal, 5)
          children_templates = attributes_for_list(:goal, 3, is_template: true, parent_id: parent.id)
          expect(Goal.is_templated_rows(user)).not_to contain_exactly(children_templates)
        end
      end
      context 'team_goals' do
        let!(:admin) { create(:user, :admin) }
        let!(:manager) { create(:user_with_teams) }
        context 'user is admin' do 
          it 'is expected to return all goals where status is open or in progress' do
            closed_goal = create(:goal, status: 2)
            open_goal = create(:goal, status: 0)
            in_progress_goal = create(:goal, status: 1)
            expect(Goal.team_goals(admin)).to match_array([open_goal, in_progress_goal])
          end
          it 'is expected to return goals where team is not nil' do
            closed_goal = create(:goal, status: 2)
            open_goal = create(:goal, status: 0)
            in_progress_goal = create(:goal, status: 1, team_id: nil)
            expect(Goal.team_goals(admin)).to match_array([open_goal])
          end
          it 'is expected not to return goals with no team' do
            closed_goal = create(:goal, status: 2)
            open_goal = create(:goal, status: 0, team_id: nil)
            in_progress_goal = create(:goal, status: 1)
            expect(Goal.team_goals(admin)).not_to match_array([open_goal])
          end
          it 'is expected to return goals from all users' do
            closed_goal = create(:goal, status: 2)
            user_goal = create(:goal, status: 0, user_id: user.id)
            manager_goal = create(:goal, status: 1, user_id: manager.id)
            admin_goal = create(:goal, status: 1, user_id: admin.id)
            expect(Goal.team_goals(admin)).to match_array([user_goal, manager_goal, admin_goal])
          end
          it 'is expected to return goals from all users if admin have managed teams' do
            admin_team = create(:team, manager_id: admin.id)
            closed_goal = create(:goal, status: 2)
            user_goal = create(:goal, status: 0, user_id: user.id)
            manager_goal = create(:goal, status: 1, user_id: manager.id)
            admin_goal = create(:goal, status: 1, user_id: admin.id, team_id: admin_team.id)
            other_user_team_goal = create(:goal, status: 1, user_id: user.id, team_id: admin_team.id)
            expect(Goal.team_goals(admin)).to match_array([user_goal, manager_goal, admin_goal, other_user_team_goal])
          end 
        end
        context 'user is manager' do
          it 'is expected to return team goals where status is open or in progress' do
            closed_goal = create(:goal, status: 2, team_id: manager.teams.first.id, user_id: manager.id)
            open_goal = create(:goal, status: 0, team_id: manager.teams.first.id, user_id: manager.id)
            in_progress_goal = create(:goal, status: 1, team_id: manager.teams.first.id, user_id: manager.id)
            expect(Goal.team_goals(manager)).to match_array([open_goal, in_progress_goal])
          end
          it 'is expected not to return team goals where status is closed succ' do
            closed_goal = create(:goal, status: 2, team_id: manager.teams.first.id, user_id: manager.id)
            open_goal = create(:goal, status: 0, team_id: manager.teams.first.id, user_id: manager.id)
            in_progress_goal = create(:goal, status: 1, team_id: manager.teams.first.id, user_id: manager.id)
            expect(Goal.team_goals(manager)).not_to include(closed_goal)
          end
          it 'is expected to return all goals from managed teams' do
            manager_team1_goal = create(:goal, team_id: manager.teams.first.id, status: 0, user_id: manager.id)
            manager_team2_goal = create(:goal, team_id: manager.teams.last.id, status: 1, user_id: manager.id)
            expect(Goal.team_goals(manager)).to match_array([manager_team1_goal, manager_team2_goal])
          end
          it "is expected not to return goals from other manager's teams" do
            manager2 = create(:user_with_teams)
            manager_team_goal = create(:goal, team_id: manager.teams.first.id, status: 0, user_id: manager.id)
            manager2_team_goal = create(:goal, team_id: manager2.teams.last.id, status: 1, user_id: manager2.id)
            expect(Goal.team_goals(manager)).not_to include(manager2_team_goal)
          end
          it 'is expected not to return goals from other teams' do
            team = create(:team)
            user_goal = create(:goal, team_id: team.id, user_id: user.id)
            manager_team_goal = create(:goal, team_id: manager.teams.first.id, status: 0, user_id: manager.id)
            expect(Goal.team_goals(manager)).not_to include(user_goal)
          end
          it 'is expected to return goals from team where manager is a member' do
            manager_member_team = create(:team)
            manager_member_team.user_ids = manager.id 
            member_team_goal = create(:goal, team_id: manager_member_team.id, status: 0)
            expect(Goal.team_goals(manager)).to match_array([member_team_goal])
          end
          it 'is expected not to return goals from team where manager is not a member' do 
            manager_member_team = create(:team)
            manager_member_team.user_ids = manager.id
            other_team = create(:team, manager_id: admin.id)
            other_team_goal =  create(:goal, team_id: other_team.id, status: 0)  
            member_teams_goal = create(:goal, team_id: manager_member_team.id, status: 0)
            expect(Goal.team_goals(manager)).not_to include(other_team_goal)
          end
        end
        context 'user is user' do
          it 'is expected to return team goals where status is open or in progress' do
            team = create(:team)
            team.user_ids = user.id
            closed_goal = create(:goal, status: 2, team_id: user.team.team_id, user_id: manager.id)
            open_goal = create(:goal, status: 0, team_id: user.team.team_id, user_id: manager.id)
            in_progress_goal = create(:goal, status: 1, team_id: user.team.team_id, user_id: manager.id)
            expect(Goal.team_goals(user)).to match_array([open_goal, in_progress_goal])
          end
          it 'is expected not to return team goals where status is closed succ' do
            team = create(:team)
            team.user_ids = user.id
            closed_goal = create(:goal, status: 2, team_id: user.team.team_id, user_id: manager.id)
            open_goal = create(:goal, status: 0, team_id: user.team.team_id, user_id: manager.id)
            in_progress_goal = create(:goal, status: 1, team_id: user.team.team_id, user_id: manager.id)
            expect(Goal.team_goals(user)).not_to include(closed_goal)
          end
          it 'is expected to return goals from users team' do
            team = create(:team)
            team.user_ids = user.id
            goal = create(:goal, status: 0, team_id: user.team.team_id, user_id: admin.id)
            expect(Goal.team_goals(user)).to include(goal)
          end
          it "is expected not to return goals from other user's team" do
            team = create(:team)
            other_team = create(:team)
            team.user_ids = user.id
            goal = create(:goal, status: 0, team_id: user.team.team_id, user_id: admin.id)
            other_team_goal = create(:goal, status: 1, team_id: other_team.id, user_id: admin.id)
            expect(Goal.team_goals(user)).not_to include(other_team_goal)
          end
          it 'is expected to return an empty relation if user has no team' do
            user.team = nil
            expect(Goal.team_goals(user)).to be_empty
          end
        end
      end
      context 'team_archive' do
        let!(:admin) { create(:user, :admin) }
        let!(:manager) { create(:user_with_teams) }
        context 'user is admin' do 
          it 'is expected to return all goals where status is closed succ' do
            closed_goal = create(:goal, status: 2)
            open_goal = create(:goal, status: 0)
            in_progress_goal = create(:goal, status: 1)
            expect(Goal.team_archive(admin)).to include(closed_goal)
          end
          it 'is expected to return goals where team is not nil' do
            closed_goal = create(:goal, status: 2)
            second_closed_goal = create(:goal, status: 2, team_id: nil)
            expect(Goal.team_archive(admin)).to include(closed_goal)
          end
          it 'is expected not to return goals with no team' do
            closed_goal = create(:goal, status: 2)
            second_closed_goal = create(:goal, status: 2, team_id: nil)
            expect(Goal.team_archive(admin)).not_to include(second_closed_goal)
          end
          it 'is expected to return goals from all users' do
            closed_goal = create(:goal, status: 2)
            user_closed_goal = create(:goal, status: 2, user_id: user.id)
            manager_closed_goal = create(:goal, status: 2, user_id: manager.id)
            admin_closed_goal = create(:goal, status: 2, user_id: admin.id)
            expect(Goal.team_archive(admin)).to match_array([closed_goal, user_closed_goal, manager_closed_goal, admin_closed_goal])
          end
          it 'is expected to return goals from all users if admin have managed teams' do
            admin_team = create(:team, manager_id: admin.id)
            closed_goal = create(:goal, status: 2)
            user_goal = create(:goal, status: 2, user_id: user.id)
            manager_goal = create(:goal, status: 2, user_id: manager.id)
            admin_goal = create(:goal, status: 2, user_id: admin.id, team_id: admin_team.id)
            other_user_team_goal = create(:goal, status: 2, user_id: user.id, team_id: admin_team.id)
            not_team_goal = create(:goal, status: 2, team_id: nil, user_id: user.id)
            expect(Goal.team_archive(admin)).to match_array([closed_goal, user_goal, manager_goal, admin_goal, other_user_team_goal])
          end
        end
        context 'user is manager' do
          it 'is expected to return team goals where status is closed' do
            closed_goal = create(:goal, status: 2, team_id: manager.teams.first.id, user_id: manager.id)
            other_closed_goal = create(:goal, status: 2, team_id: manager.teams.last.id, user_id: manager.id)
            expect(Goal.team_archive(manager)).to match_array([closed_goal, other_closed_goal])
          end
          it 'is expected not to return team goals where status is open or in progress' do
            closed_goal = create(:goal, status: 2, team_id: manager.teams.first.id, user_id: manager.id)
            open_goal = create(:goal, status: 0, team_id: manager.teams.first.id, user_id: manager.id)
            in_progress_goal = create(:goal, status: 1, team_id: manager.teams.first.id, user_id: manager.id)
            expect(Goal.team_archive(manager)).not_to include([open_goal, in_progress_goal])
          end
          it 'is expected to return all closed goals from managed teams' do
            manager_team1_goal = create(:goal, team_id: manager.teams.first.id, status: 2, user_id: manager.id)
            manager_team2_goal = create(:goal, team_id: manager.teams.last.id, status: 2, user_id: manager.id)
            expect(Goal.team_archive(manager)).to match_array([manager_team1_goal, manager_team2_goal])
          end
          it "is expected not to return closed goals from other manager's teams" do
            manager2 = create(:user_with_teams)
            manager_team_goal = create(:goal, team_id: manager.teams.first.id, status: 2, user_id: manager.id)
            manager2_team_goal = create(:goal, team_id: manager2.teams.last.id, status: 2, user_id: manager2.id)
            expect(Goal.team_archive(manager)).not_to include(manager2_team_goal)
          end
          it 'is expected not to return closed goals from other teams' do
            team = create(:team)
            user_goal = create(:goal, status: 2, team_id: team.id, user_id: user.id)
            manager_team_goal = create(:goal, status: 2, team_id: manager.teams.first.id, user_id: manager.id)
            expect(Goal.team_archive(manager)).not_to include(user_goal)
          end
          it 'is expected to return closed goals from team where manager is a member' do
            manager_member_team = create(:team, manager_id: user.id)
            manager_member_team.user_ids = manager.id 
            member_teams_goal = create(:goal, status: 2, user_id: user.id, team_id: manager_member_team.id)
            expect(Goal.team_archive(manager)).to include(member_teams_goal)
          end
          it 'is expected not to return closed goals from team where manager is not a member' do 
            manager_member_team = create(:team, manager_id: user.id)
            manager_member_team.user_ids = manager.id
            other_team = create(:team, manager_id: admin.id)
            other_teams_goal =  create(:goal, user_id: admin.id, team_id: other_team.id, status: 2)  
            member_teams_goal = create(:goal, user_id: user.id, team_id: manager_member_team.id, status: 2)
            expect(Goal.team_archive(manager)).not_to include(other_teams_goal)
          end
        end
        context 'user is user' do
          it 'is expected to return closed team goals where status is closed succ' do
            team = create(:team)
            team.user_ids = user.id
            closed_goal = create(:goal, status: 2, team_id: user.team.team_id, user_id: manager.id)
            other_closed_goal = create(:goal, status: 2, team_id: user.team.team_id, user_id: manager.id)
            open_goal = create(:goal, status: 0, team_id: user.team.team_id, user_id: manager.id)
            in_progress_goal = create(:goal, status: 1, team_id: user.team.team_id, user_id: manager.id)
            expect(Goal.team_archive(user)).to match_array([closed_goal, other_closed_goal])
          end
          it 'is expected not to return closed team goals where status is open or in progress' do
            team = create(:team)
            team.user_ids = user.id
            closed_goal = create(:goal, status: 2, team_id: user.team.team_id, user_id: manager.id)
            open_goal = create(:goal, status: 0, team_id: user.team.team_id, user_id: manager.id)
            in_progress_goal = create(:goal, status: 1, team_id: user.team.team_id, user_id: manager.id)
            expect(Goal.team_archive(user)).not_to match_array([open_goal, in_progress_goal])
          end
          it 'is expected to return closed goals from users team' do
            team = create(:team)
            team.user_ids = user.id
            goal = create(:goal, status: 2, team_id: user.team.team_id, user_id: admin.id)
            expect(Goal.team_archive(user)).to include(goal)
          end
          it "is expected not to return closed goals from other user's team" do
            team = create(:team)
            other_team = create(:team)
            team.user_ids = user.id
            goal = create(:goal, status: 2, team_id: user.team.team_id, user_id: admin.id)
            other_team_goal = create(:goal, status: 2, team_id: other_team.id, user_id: admin.id)
            expect(Goal.team_goals(user)).not_to include(other_team_goal)
          end
          it 'is expected to return an empty relation if user has no team' do
            user.team = nil
            expect(Goal.team_goals(user)).to be_empty
          end
        end
      end
    end
    describe 'Class methods' do
      let!(:user) { create(:user) }
      let!(:manager) { create(:user_with_teams) }
      let!(:admin) { create(:user, :admin) }
      describe 'search' do
        context 'user is admin' do
          before(:each) do
            @user_goal = create(:goal, user_id: user.id, team_id: nil, start_date: Date.today)
            @manager_goal = create(:goal, user_id: manager.id, team_id: nil, start_date: Date.today)
            @admin_goal = create(:goal, user_id: admin.id, team_id: nil, start_date: Date.today)
          end
          it 'is expected to return all goals if blank parameters were given' do
            params = { search: { } } 
            expect(Goal.search(params[:search], admin).count).to eq(3)
          end
          it 'is expected to return goals from all users' do
            params = { search: { 'start_date' => Date.today } }
            expect(Goal.search(params[:search], admin)).to match_array([@user_goal, @manager_goal, @admin_goal])
          end
          it 'is expected to return templates' do
            params = { search: { 'name' => 'Foo' } }
            template = create(:goal, user_id: manager.id, team_id: nil, is_template: true, name: 'Foo')
            expect(Goal.search(params[:search], admin)).to match_array([template])
          end
          it 'is expected to return team goals' do
            params = { search: { 'name' => 'Foo' } }
            team_goal = create(:goal, user_id: manager.id, name: 'Foo')
            expect(Goal.search(params[:search], admin)).to match_array([team_goal])
          end
          it 'is expected to search by start_date' do
            params = { search: { 'start_date' => Date.tomorrow } }
            user_goal = create(:goal, user_id: user.id, team_id: nil, start_date: Date.tomorrow)
            expect(Goal.search(params[:search], admin)).to match_array([user_goal])
          end
          it 'is expected to search by end_date' do
            params = { search: { 'end_date' => Date.today } }
            user_goal = create(:goal, user_id: user.id, team_id: nil, end_date: Date.today)
            expect(Goal.search(params[:search], admin)).to match_array([user_goal])
          end
          it 'is expected to search by goal name' do
            params = { search: { 'name' => "foo" } }
            user_goal = create(:goal, user_id: user.id, team_id: nil, name: "foo")
            expect(Goal.search(params[:search], admin)).to match_array([user_goal])
          end
          it 'is expected to ignore upper cased letter in goal name' do
            params = { search: { 'name' => "foo" } }
            user_goal = create(:goal, user_id: user.id, team_id: nil, name: "Foo")
            expect(Goal.search(params[:search], admin)).to contain_exactly(user_goal)
          end
          it 'is expected to search by team id' do
            team = create(:team, name: 'FooTeam')
            params = { search: { 'team_id' => team.id } }
            user_goal = create(:goal, user_id: user.id, team_id: team.id, name: "Foo")
            expect(Goal.search(params[:search], admin)).to contain_exactly(user_goal)
          end
          it 'is expected to search by user id' do
            params = { search: { 'user_id' => user.id } }
            expect(Goal.search(params[:search], admin)).to match_array([@user_goal])
          end
          it 'is expected to search by category id' do
            category = create(:category, name: 'Bla')
            params = { search: { category_id: category.id } }
            user_goal = create(:goal, user_id: user.id, team_id: nil, name: "Foo")
            user_goal.category_ids = [category.id]
            expect(Goal.search(params[:search], admin)).to match_array([user_goal])
          end
          it 'is expected to chain query' do
            team = create(:team, name: 'FooTeam')
            team2 = create(:team, name: 'Second')
            user_goal = create(:goal, user_id: user.id, team_id: team.id, name: "Foo")
            user2_goal = create(:goal, user_id: user.id, team_id: team2.id, name: "Foo")
            params = { search: { 'user_id' => user.id, 'team_id' => team.id, 'name' => 'foo' } }
            expect(Goal.search(params[:search], admin)).to match_array([user_goal])
          end
          context 'scopes' do
            it 'is expected to search all goals if scope is not given' do
              params = { search: { 'name' => 'foo', scope: nil } }
              open_goal =  create(:goal, user_id: admin.id, team_id: nil, name: "foo", status: 1)
              closed_goal = create(:goal, user_id: admin.id, name: "foo", status: 2)
              template = create(:goal, name: 'foo', is_template: true)
              team_goal = create(:goal, name: 'foo')
              expect(Goal.search(params[:search], admin)).to match_array([closed_goal, open_goal, template, team_goal])         
            end
            it 'is expected to use scoped collection if scope is given' do
              params = { search: { 'name' => 'foo', scope: :are_closed } }
              closed_goal =  create(:goal, user_id: admin.id, team_id: nil, name: "foo", status: 2)
              closed_team_goal = create(:goal, user_id: admin.id, name: "foo", status: 2)
              template = create(:goal, name: 'foo', is_template: true)
              team_goal = create(:goal, name: 'foo')
              expect(Goal.search(params[:search], admin)).to match_array([closed_goal]) 
            end
          end
        end
        context 'user is manager' do
          before(:each) do
            @subordinated_user = create(:user)
            manager.teams.first.user_ids = @subordinated_user.id
            @user_goal = create(:goal, user_id: user.id, team_id: nil, start_date: Date.today)
            @manager_goal = create(:goal, user_id: manager.id, team_id: nil, start_date: Date.today)
            @admin_goal = create(:goal, user_id: admin.id, team_id: nil, start_date: Date.today)
          end
          it 'is expected to return goals from subordinated users and self if blank parameters were given' do
            params = { search: { } }
            subordinated_users_goal = create(:goal, user_id: @subordinated_user.id, team_id: nil)
            expect(Goal.search(params[:search], manager)).to match_array([subordinated_users_goal, @manager_goal])
          end
          it 'is expected to return goals from self and subordinated users if search parameters were given' do
            params = { search: { 'start_date' => Date.today } }
            subordinated_users_goal = create(:goal, user_id: @subordinated_user.id, team_id: nil, start_date: Date.today)
            expect(Goal.search(params[:search], manager)).to match_array([subordinated_users_goal, @manager_goal])
          end
          it 'is expected to return templates' do
            params = { search: { 'name' => 'Foo' } }
            template = create(:goal, user_id: admin.id, team_id: nil, is_template: true, name: 'Foo')
            expect(Goal.search(params[:search], manager)).to match_array([template])
          end
          it 'is expected to return managed or own team goals' do
            params = { search: { 'name' => 'Foo' } }
            team_goal = create(:goal, user_id: manager.id, name: 'Foo', team_id: manager.teams.first.id)
            expect(Goal.search(params[:search], manager)).to match_array([team_goal])
          end
          it 'is expected not to return other managers team goals if is not in that team' do
            params = { search: { 'name' => 'Foo' } }
            other_manager = create(:user_with_teams)
            team_goal = create(:goal, user_id: manager.id, name: 'Foo', team_id: manager.teams.first.id)
            other_team_goal = create(:goal, user_id: other_manager.id, name: 'Foo', team_id: other_manager.teams.first.id)
            expect(Goal.search(params[:search], manager)).not_to include(other_team_goal)
          end
          it 'is expected to return other team goals if manager is user of that team' do
            params = { search: { 'name' => 'Foo' } }
            other_manager = create(:user_with_teams)
            other_manager.teams.first.user_ids = manager.id
            team_goal = create(:goal, user_id: manager.id, name: 'Foo', team_id: manager.teams.first.id)
            other_team_goal = create(:goal, name: 'Foo', user_id:other_manager.id, team_id: other_manager.teams.first.id)
            expect(Goal.search(params[:search], manager)).to match_array([team_goal, other_team_goal])
          end
          it 'is expected to search by start_date' do
            params = { search: { 'start_date' => Date.tomorrow } }
            subordinated_users_goal = create(:goal, user_id: @subordinated_user.id, team_id: nil, start_date: Date.tomorrow)
            manager_goal = create(:goal, user_id: manager.id, team_id: nil, start_date: Date.tomorrow)
            expect(Goal.search(params[:search], manager)).to match_array([manager_goal, subordinated_users_goal])
          end
          it 'is expected to search by end_date' do
            params = { search: { 'end_date' => Date.today } }
            subordinated_users_goal = create(:goal, user_id: @subordinated_user.id, team_id: nil, end_date: Date.today)
            manager_goal = create(:goal, user_id: manager.id, team_id: nil, end_date: Date.today)
            expect(Goal.search(params[:search], manager)).to match_array([manager_goal, subordinated_users_goal])
          end
          it 'is expected to search by goal name' do
            params = { search: { 'name' => "foo" } }
            manager_goal = create(:goal, user_id: manager.id, team_id: nil, name: "foo")
            subordinated_users_goal = create(:goal, user_id: @subordinated_user.id, team_id: nil, name: 'foo')
            expect(Goal.search(params[:search], manager)).to match_array([manager_goal, subordinated_users_goal])
          end
          it 'is expected to ignore upper cased letter in goal name' do
            params = { search: { 'name' => "foo" } }
            manager_goal = create(:goal, user_id: manager.id, team_id: nil, name: "Foo")
            expect(Goal.search(params[:search], manager)).to match_array([manager_goal])
          end
          it 'is expected to search by team id' do
            team = create(:team, name: 'FooTeam')
            params = { search: { 'team_id' => team.id } }
            subordinated_users_goal = create(:goal, user_id: @subordinated_user.id, team_id: nil, name: 'Foo')
            manager_goal = create(:goal, user_id: manager.id, team_id: team.id, name: "Foo")
            expect(Goal.search(params[:search], manager)).to match_array([manager_goal])
          end
          it 'is expected to search by user id' do
            params = { search: { 'user_id' => manager.id } }
            expect(Goal.search(params[:search], manager)).to match_array([@manager_goal])
          end
          it 'is expected to return subordinated users goals when searched by user id' do
            params = { search: { 'user_id' => @subordinated_user.id } }
            subordinated_users_goal = create(:goal, user_id: @subordinated_user.id, team_id: nil, name: 'foo')
            expect(Goal.search(params[:search], manager)).to match_array([subordinated_users_goal])
          end
          it 'is expected not to return goals from users not in managers teams' do
            params = { search: { 'user_id' => user.id } }
            expect(Goal.search(params[:search], manager)).not_to include(@user_goal)
          end
          it 'is expected to search by category id' do
            category = create(:category, name: 'Bla')
            params = { search: { category_id: category.id } }
            subordinated_user_goal = create(:goal, user_id: @subordinated_user.id, team_id: nil)
            subordinated_user_goal.category_ids = [category.id]
            expect(Goal.search(params[:search], manager)).to match_array([subordinated_user_goal])
          end
          it 'is expected to chain query' do
            team = create(:team, name: 'FooTeam')
            team2 = create(:team, name: 'Second')
            manager_goal = create(:goal, user_id: manager.id, team_id: team.id, name: "Foo")
            manager2_goal = create(:goal, user_id: manager.id, team_id: team2.id, name: "Foo")
            params = { search: { 'user_id' => manager.id, 'team_id' => team.id, 'name' => 'foo' } }
            expect(Goal.search(params[:search], manager)).to match_array([manager_goal])
          end
          context 'scopes' do
            it 'is expected to search all availible goals if scope is not given' do
              other_manager = create(:user_with_teams)
              other_manager.teams.first.user_ids = manager.id
              params = { search: { 'name' => 'foo', scope: nil } }
              open_goal =  create(:goal, user_id: @subordinated_user.id, team_id: nil, name: "foo", status: 1)
              closed_goal = create(:goal, user_id: manager.id, name: "foo", status: 2)
              template = create(:goal, name: 'foo', is_template: true, team_id: nil, user_id: admin.id)
              team_goal = create(:goal, name: 'foo', team_id: manager.teams.first.id, user_id: manager.id)
              managers_team_goal = create(:goal, name: 'Foo', user_id: other_manager.id, team_id: other_manager.teams.first.id)
              expect(Goal.search(params[:search], manager)).to match_array([closed_goal, open_goal, template, team_goal, managers_team_goal])         
            end
            it 'is expected to use scoped collection if scope is given' do
              params = { search: { 'name' => 'foo', scope: :are_closed } }
              closed_goal =  create(:goal, user_id: manager.id, team_id: nil, name: "foo", status: 2)
              closed_team_goal = create(:goal, user_id: manager.id, name: "foo", status: 2, team_id: manager.teams.first.id)
              template = create(:goal, name: 'foo', is_template: true)
              team_goal = create(:goal, name: 'foo')
              expect(Goal.search(params[:search], manager)).to match_array([closed_goal]) 
            end
          end
        end
        context 'user is user' do
          before(:each) do
            @user_goal = create(:goal, user_id: user.id, team_id: nil, start_date: Date.today)
            manager.teams.first.user_ids = user.id
            @manager_goal = create(:goal, user_id: manager.id, team_id: nil, start_date: Date.today)
            @admin_goal = create(:goal, user_id: admin.id, team_id: nil, start_date: Date.today)
          end
          it 'is expected to return goals only from self when blank seach parameters were given' do
            params = { search: { } }
            expect(Goal.search(params[:search], user)).to match_array([@user_goal])
          end
          it 'is expected to return templates' do
            params = { search: { 'name' => 'Foo' } }
            template = create(:goal, user_id: admin.id, team_id: nil, is_template: true, name: 'Foo')
            expect(Goal.search(params[:search], user)).to match_array([template])
          end
          it 'is expected not to return goals that belongs to users team' do
            params = { search: { 'name' => 'Foo' } }
            team_goal = create(:goal, user_id: manager.id, name: 'Foo', team_id: user.team.team_id)
            expect(Goal.search(params[:search], user)).not_to include(team_goal)
          end
          it 'is expected not to return team goals if is not in that team' do
            params = { search: { 'name' => 'Foo' } }
            team_goal = create(:goal, user_id: manager.id, name: 'Foo', team_id: manager.teams.first.id)
            other_team_goal = create(:goal, user_id: manager.id, name: 'Foo', team_id: manager.teams.last.id)
            expect(Goal.search(params[:search], user)).not_to include(other_team_goal)
          end
          it 'is expected to search by start_date' do
            params = { search: { 'start_date' => Date.tomorrow } }
            user_goal = create(:goal, user_id: user.id, team_id: nil, start_date: Date.tomorrow)
            manager_goal = create(:goal, user_id: manager.id, team_id: nil, start_date: Date.tomorrow)
            expect(Goal.search(params[:search], user)).to match_array([user_goal])
          end
          it 'is expected to search by end_date' do
            params = { search: { 'end_date' => Date.today } }
            user_goal = create(:goal, user_id: user.id, team_id: nil, end_date: Date.today)
            manager_goal = create(:goal, user_id: manager.id, team_id: nil, end_date: Date.today)
            expect(Goal.search(params[:search], user)).to match_array([user_goal])
          end
          it 'is expected to search by goal name' do
            params = { search: { 'name' => "foo" } }
            user_goal = create(:goal, user_id: user.id, team_id: nil, name: "foo")
            managers_goal = create(:goal, user_id: manager.id, team_id: nil, name: 'foo')
            expect(Goal.search(params[:search], user)).to match_array([user_goal])
          end
          it 'is expected to ignore upper cased letter in goal name' do
            params = { search: { 'name' => "foo" } }
            user_goal = create(:goal, user_id: user.id, team_id: nil, name: "Foo")
            expect(Goal.search(params[:search], user)).to match_array([user_goal])
          end
          it 'is expected not to search by team id' do
            params = { search: { 'team_id' => manager.teams.first.id } }
            users_team_goal = create(:goal, user_id: manager.id, team_id: manager.teams.first.id, name: "Foo")
            expect(Goal.search(params[:search], user)).not_to match_array([users_team_goal])
          end
          it 'is expected not to search by user id' do
            params = { search: { 'user_id' => manager.id } }
            expect(Goal.search(params[:search], user)).not_to match_array([@manager_goal])
          end
          it 'is expected to search by category id' do
            category = create(:category, name: 'Bla')
            params = { search: { category_id: category.id } }
            user_goal = create(:goal, user_id: user.id, team_id: nil)
            user_goal.category_ids = [category.id]
            expect(Goal.search(params[:search], user)).to match_array([user_goal])
          end
          it 'is expected to chain query' do
            user_goal = create(:goal, user_id: user.id, start_date: Date.today, end_date: Date.tomorrow, name: "Foo")
            user2_goal = create(:goal, user_id: user.id, start_date: Date.today, name: "Foo", end_date: 2.days.from_now)
            params = { search: { 'name' => 'foo', 'start_date' => Date.today, 'end_date' => Date.tomorrow } }
            expect(Goal.search(params[:search], user)).to match_array([user_goal])
          end
          context 'scopes' do
            it 'is expected to search all availible goals if scope is not given' do
              params = { search: { 'name' => 'foo', scope: nil } }
              open_goal =  create(:goal, user_id: user.id, team_id: nil, name: "foo", status: 1)
              closed_goal = create(:goal, user_id: user.id, name: "foo", status: 2)
              template = create(:goal, name: 'foo', is_template: true, team_id: nil, user_id: admin.id)
              team_goal = create(:goal, name: 'foo', team_id: manager.teams.first.id, user_id: manager.id)
              expect(Goal.search(params[:search], user)).to match_array([closed_goal, open_goal, template])         
            end
            it 'is expected to use scoped collection if scope is given' do
              params = { search: { 'name' => 'foo', scope: :are_closed } }
              closed_goal =  create(:goal, user_id: user.id, team_id: nil, name: "foo", status: 2)
              closed_team_goal = create(:goal, user_id: manager.id, name: "foo", status: 2, team_id: manager.teams.first.id)
              template = create(:goal, name: 'foo', is_template: true)
              team_goal = create(:goal, name: 'foo', team_id: manager.teams.first.id, user_id: manager.id)
              expect(Goal.search(params[:search], user)).to match_array([closed_goal]) 
            end
          end
        end
      end
      describe 'batch' do
        let(:valid_list) { create_list(:goal, 5, team_id: nil, user_id: user.id, parent_id: nil) }
        let(:invalid_list) { create_list(:goal, 5, team_id: nil, user_id: manager.id, parent_id: nil) }
        context 'destroy action' do
          before(:each) do |bfr|
            unless bfr.metadata[:skip_before]
              valid_list
              ids = Goal.all.pluck(:id)
              Goal.batch(ids, user, 'delete')
            end
          end
          it 'destroys goals if user have a permission' do
            expect(Goal.count).to eq(0)
          end
          it 'does not destroy goals if user havent got a permission', :skip_before do
            invalid_list
            Goal.batch(Goal.all.pluck(:id), user, 'delete')
            expect(Goal.count).to eq(5)
          end
        end
        context 'archive action' do
          before(:each) do |bfr|
            unless bfr.metadata[:skip_before]
              @valid_goal1 = create(:goal, team_id: nil, user_id: user.id, parent_id: nil)
              @valid_goal2 = create(:goal, team_id: nil, user_id: user.id, parent_id: nil)
              ids = Goal.all.pluck(:id)
              Goal.batch(ids, user, 'archive')
            end
          end
          it 'changes goals status to closed_succ if user have a permission' do
            @valid_goal1.reload
            @valid_goal2.reload
            expect([@valid_goal1.status, @valid_goal2.status]).to contain_exactly("closed_succ", "closed_succ")
          end
          it 'does not change goals status if user havent got a permission', :skip_before do
            valid_goal = create(:goal, team_id: nil, user_id: user.id, parent_id: nil)
            unvalid_goal = create(:goal, team_id: nil, user_id: manager.id, parent_id: nil)
            ids = Goal.all.pluck(:id)
            Goal.batch(ids, user, 'archive')
            valid_goal.reload
            unvalid_goal.reload
            expect([valid_goal.status, unvalid_goal.status]).to contain_exactly("closed_succ", "open")
          end
        end
      end
    end
  end
end