require 'rails_helper'

RSpec.describe Team, type: :model do
  describe 'Associations' do
    it { is_expected.to have_many(:team_users) }
    it { is_expected.to have_many(:users) }
    it { is_expected.to have_many(:goals) }
    it { is_expected.to belong_to(:manager) }
  end
  describe 'Validations' do
    it { is_expected.to validate_length_of(:name) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:manager) }
    it { is_expected.to validate_uniqueness_of(:name) }
  end
  describe 'Scopes' do
    context ':users_teams' do
      let(:team1) { create(:team) }
      let(:team2) { create(:team) }
      let(:team3) { create(:team) }
      context 'user is admin' do
        before(:each) do 
          @admin = create(:user, :admin)
        end
        it 'is expected to return all existing teams' do
          team1
          team2
          team3
          expect(Team.users_teams(@admin)).to contain_exactly(team1, team2, team3)
        end
        context 'user is manager' do
          let(:managed_team1) { create(:team, manager_id: @manager.id) }
          let(:managed_team2) { create(:team, manager_id: @manager.id) }
          before(:each) do
            @manager = create(:user)
          end
          it 'is expected to return all managed teams' do
            team1
            team2
            managed_team1
            managed_team2
            expect(Team.users_teams(@manager)).to contain_exactly(managed_team1, managed_team2)
          end
          it 'is expected to return all teams where manager is a user' do
            team1
            team1.user_ids = @manager.id
            team2
            expect(Team.users_teams(@manager)).to contain_exactly(team1)
          end
          it 'is expected to return both(managed teams and teams, where manager is a user)' do
            team1
            team1.user_ids = @manager.id
            team2
            managed_team1
            expect(Team.users_teams(@manager)).to contain_exactly(managed_team1, team1)
          end
          context 'user is user' do
            it 'is expected to return nothing if user is a user' do
              user = create(:user, role: 0)
              team1
              team2
              team3
              expect(Team.users_teams(user)).to be_empty
            end
          end
        end
      end
    end
  end
  describe 'Methods' do
    describe 'search' do
      let(:team1) { create(:team) }
      let(:team2) { create(:team) }
      let(:team3) { create(:team) }
      before(:each) do
        @admin = create(:user, :admin)
      end
      it 'is expected to search by team name' do
        team = create(:team, name: 'Foo')
        params = { 'name' => team.id }
        team1
        team2
        expect(Team.search(params, @admin)).to contain_exactly(team)
      end
      it 'is expected to search by user' do
        team1
        team2
        team3
        user = create(:user, name: 'Ivan')
        team1.user_ids = user.id
        params = { user_name: 'Ivan' }.with_indifferent_access
        expect(Team.search(params, @admin)).to contain_exactly(team1)
      end
      it 'is expected to search by team goals' do
        team1 
        team1_goal = create(:goal, team_id: team1.id)
        team2
        team2_goal = create(:goal, team_id: team2.id)
        params = { goal_id: team1_goal.id }.with_indifferent_access
        expect(Team.search(params, @admin)).to contain_exactly(team1)
      end
      it 'is expected to search by team manager' do
        team1
        team2
        team3
        manager = create(:user)
        managed_team = create(:team, manager_id: manager.id)
        params = { manager_id: manager.id }.with_indifferent_access
        expect(Team.search(params, @admin)).to contain_exactly(managed_team)
      end
      it 'is expected to search by creation date' do
        team3 = create(:team, created_at: Date.tomorrow)
        team2 = create(:team, created_at: 2.days.from_now)
        team1 = create(:team, created_at: Date.today)
        params = { created_at: Date.today }.with_indifferent_access
        expect(Team.search(params, @admin)).to contain_exactly(team1)
      end
      it 'is expected to search by date of the last update' do
        team3 = create(:team, updated_at: Date.tomorrow)
        team2 = create(:team, updated_at: 2.days.from_now)
        team1
        params = { updated_at: Date.today }.with_indifferent_access
        expect(Team.search(params, @admin)).to contain_exactly(team1)
      end
      it 'is expected to chain query' do
        team1
        team2
        team3
        team = create(:team, name: 'foo', created_at: Date.tomorrow)
        team_goal = create(:goal, team_id: team.id)
        team1_goal = create(:goal, team_id: team1.id)
        params = { created_at: Date.tomorrow, name: team.id, goal_id: team_goal.id }.with_indifferent_access
        expect(Team.search(params, @admin)).to contain_exactly(team)
      end
      it 'is expected to search only available teams for manager' do
        manager = create(:user_with_teams)
        other_manager = create(:user_with_teams)
        params = { created_at: Date.today }.with_indifferent_access
        expect(Team.search(params, manager).count).to eq(manager.teams.count)
      end
    end
    describe 'batch' do
      let(:user) { create(:user) }
      let(:admin) { create(:user, :admin) }
      let(:team_list) { create_list(:team, 5) }
      context 'destroy action' do
        before(:each) do |bfr|
          unless bfr.metadata[:skip_before]
            team_list
            ids = Team.all.pluck(:id)
            Team.batch(ids, admin, 'delete')
          end
        end
        it 'destroys teams if user have a permission' do
          expect(Team.count).to eq(0)
        end
        it 'does not destroy teams if user havent got a permission', :skip_before do
          team_list
          Team.batch(Team.all.pluck(:id), user, 'delete')
          expect(Team.count).to eq(5)
        end
      end
    end
  end
end
