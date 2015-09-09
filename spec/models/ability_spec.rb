require 'rails_helper'
require "cancan/matchers"

Rails.describe Ability, type: :model do
  describe "abilities" do

    context "when is an admin" do
      before(:each) do
        @user = build_stubbed(:user)
        @admin = create(:user, :admin)
        @ability = Ability.new(@admin)
      end
      it { expect(@ability).to be_able_to(:create, Goal) }
      it { expect(@ability).to be_able_to(:update, Goal.new(user_id: @admin.id)) }
      it { expect(@ability).to be_able_to(:update, Goal.new(user_id: @admin.id, status: 0)) }
      it { expect(@ability).to be_able_to(:update, Goal.new(user_id: @admin.id, status: 1)) }
      it { expect(@ability).to be_able_to(:update, Goal.new(user_id: @admin.id, status: nil)) }
      it { expect(@ability).to be_able_to(:update, Goal.new(user_id: @admin.id, status: 3)) }
      it { expect(@ability).not_to be_able_to(:update, Goal.new(user_id: @admin.id, status: 2)) }
      it { expect(@ability).not_to be_able_to(:update, Goal.new(user_id: nil)) }
      it { expect(@ability).not_to be_able_to(:update, Goal.new(user_id: @user.id)) }
      it { expect(@ability).to be_able_to(:destroy, Goal.new(user_id: @admin.id)) }
      it { expect(@ability).to be_able_to(:destroy, Goal.new(user_id: @admin.id, status: 0)) }
      it { expect(@ability).to be_able_to(:destroy, Goal.new(user_id: @admin.id, status: 1)) }
      it { expect(@ability).to be_able_to(:destroy, Goal.new(user_id: @admin.id, status: nil)) }
      it { expect(@ability).to be_able_to(:destroy, Goal.new(user_id: @admin.id, status: 3)) }
      it { expect(@ability).not_to be_able_to(:destroy, Goal.new(user_id: @admin.id, status: 2)) }
      it { expect(@ability).not_to be_able_to(:destroy, Goal.new(user_id: nil)) }
      it { expect(@ability).not_to be_able_to(:destroy, Goal.new(user_id: @user.id)) }
      # it { expect(@ability).not_to be_able_to(:destroy, Goal.new(user_id: @admin.id, is_template_based: true)) }
      it { expect(@ability).to be_able_to(:update, Goal.new(user_id: @admin.id, is_template: true)) }
      it { expect(@ability).not_to be_able_to(:update, Goal.new(user_id: @user.id, is_template: true)) }
      it { expect(@ability).to be_able_to(:destroy, Goal.new(user_id: @admin.id, is_template: true)) }
      it { expect(@ability).not_to be_able_to(:destroy, Goal.new(user_id: @user.id, is_template: true)) }
      it { expect(@ability).to be_able_to(:new_template, Goal) }
      it { expect(@ability).to be_able_to(:create_template, Goal) }
      it { expect(@ability).to be_able_to(:create_from_template, Goal) }
      it { expect(@ability).to be_able_to(:new_from_template, Goal) }
      it { expect(@ability).to be_able_to(:manage, Category) }
      it { expect(@ability).to be_able_to(:manage, Team) }
      it { expect(@ability).to be_able_to(:read, :all) }
    end
    context 'when is manager' do
      before(:each) do
        @managers_team_user = create(:user)
        @manager = create(:user_with_teams)
        manager_team = create(:team)
        manager_team.user_ids = @manager.id
        @manager.teams.first.user_ids = @managers_team_user.id
        @other_team_user = create(:user)
        other_team = create(:team)
        other_team.user_ids = @other_team_user.id
        @ability = Ability.new(@manager)
      end
      it { expect(@ability).to be_able_to(:create, Goal) }
      it { expect(@ability).to be_able_to(:read, Goal.new(is_template: true)) }
      it { expect(@ability).to be_able_to(:read, Goal.new(user_id: @manager.id)) }
      it { expect(@ability).to be_able_to(:read, Goal.new(user_id: @manager.id, status: 0)) }
      it { expect(@ability).to be_able_to(:read, Goal.new(user_id: @manager.id, status: 1)) }
      it { expect(@ability).to be_able_to(:read, Goal.new(user_id: @manager.id, status: 2)) }
      it { expect(@ability).to be_able_to(:read, Goal.new(user_id: @manager.id, status: 3)) }
      it { expect(@ability).to be_able_to(:read, Goal.new(user_id: @manager.id, status: nil)) }
      it { expect(@ability).to be_able_to(:read, Goal.new(user_id: @managers_team_user.id)) }
      it { expect(@ability).to be_able_to(:read, Goal.new(user_id: @managers_team_user.id, status: 0)) }
      it { expect(@ability).to be_able_to(:read, Goal.new(user_id: @managers_team_user.id, status: 1)) }
      it { expect(@ability).to be_able_to(:read, Goal.new(user_id: @managers_team_user.id, status: 2)) }
      it { expect(@ability).to be_able_to(:read, Goal.new(user_id: @managers_team_user.id, status: 3)) }
      it { expect(@ability).to be_able_to(:read, Goal.new(user_id: @managers_team_user.id, status: nil)) }
      it { expect(@ability).not_to be_able_to(:read, Goal.new(user_id: @other_team_user.id)) }
      it { expect(@ability).to be_able_to(:read, Goal.new(team_id: @manager.teams.first.id, status: 2)) }
      it { expect(@ability).not_to be_able_to(:read, Goal.new(team_id: @other_team_user.team.team_id)) }
      it { expect(@ability).to be_able_to(:update, Goal.new(is_template: true, user_id: @manager.id)) }
      it { expect(@ability).not_to be_able_to(:update, Goal.new(is_template: true, user_id: @other_team_user.id)) }
      it { expect(@ability).to be_able_to(:destroy, Goal.new(is_template: true, user_id: @manager.id)) }
      it { expect(@ability).not_to be_able_to(:destroy, Goal.new(is_template: true, user_id: @other_team_user.id)) }
      # it { expect(@ability).not_to be_able_to(:destroy, Goal.new(user_id: @manager.id, is_template_based: true)) }
      it { expect(@ability).to be_able_to(:read, Goal.new(is_template: true, user_id: @manager.id)) }
      it { expect(@ability).to be_able_to(:update, Goal.new(user_id: @manager.id, status: nil, team_id: @manager.teams.first.id)) }
      it { expect(@ability).to be_able_to(:update, Goal.new(user_id: @manager.id, status: 0, team_id: @manager.teams.first.id)) }
      it { expect(@ability).to be_able_to(:update, Goal.new(user_id: @manager.id, status: 1, team_id: @manager.teams.first.id)) }
      it { expect(@ability).to be_able_to(:update, Goal.new(user_id: @manager.id, status: 3, team_id: @manager.teams.first.id)) }
      it { expect(@ability).not_to be_able_to(:update, Goal.new(user_id: @manager.id, status: 2, team_id: @manager.teams.first.id)) }

      it { expect(@ability).to be_able_to(:update, Goal.new(team_id: @manager.teams.first.id)) }
      it { expect(@ability).to be_able_to(:read, Goal.new(team_id: @manager.teams.first.id)) }
      it { expect(@ability).to be_able_to(:destroy, Goal.new(team_id: @manager.teams.first.id)) }

      it { expect(@ability).to be_able_to(:destroy, Goal.new(user_id: @manager.id, status: nil, team_id: @manager.teams.first.id)) }
      it { expect(@ability).to be_able_to(:destroy, Goal.new(user_id: @manager.id, status: 0, team_id: @manager.teams.first.id)) }
      it { expect(@ability).to be_able_to(:destroy, Goal.new(user_id: @manager.id, status: 1, team_id: @manager.teams.first.id)) }
      it { expect(@ability).to be_able_to(:destroy, Goal.new(user_id: @manager.id, status: 3, team_id: @manager.teams.first.id)) }
      it { expect(@ability).not_to be_able_to(:destroy, Goal.new(user_id: @manager.id, status: 2, team_id: @manager.teams.first.id)) }
      it { expect(@ability).to be_able_to(:read, Goal.new(user_id: @manager.id, status: nil, team_id: @manager.teams.first.id)) }
      it { expect(@ability).to be_able_to(:read, Goal.new(user_id: @manager.id, status: 0, team_id: @manager.teams.first.id)) }
      it { expect(@ability).to be_able_to(:read, Goal.new(user_id: @manager.id, status: 1, team_id: @manager.teams.first.id)) }
      it { expect(@ability).to be_able_to(:read, Goal.new(user_id: @manager.id, status: 3, team_id: @manager.teams.first.id)) }
      it { expect(@ability).to be_able_to(:read, Goal.new(user_id: @manager.id, status: nil, team_id: @other_team_user.team.team_id)) }
      it { expect(@ability).to be_able_to(:read, Goal.new(user_id: @manager.id, status: nil, team_id: nil)) }
      it { expect(@ability).to be_able_to(:read, Goal.new(user_id: @manager.id, status: 0, team_id: nil)) }
      it { expect(@ability).to be_able_to(:read, Goal.new(user_id: @manager.id, status: 1, team_id: nil)) }
      it { expect(@ability).to be_able_to(:read, Goal.new(user_id: @manager.id, status: 3, team_id: nil)) }
      it { expect(@ability).not_to be_able_to(:read, Goal.new(user_id: @other_team_user.id, status: nil, team_id: nil)) }
      it { expect(@ability).to be_able_to(:update, Goal.new(user_id: @manager.id, status: nil, team_id: nil)) }
      it { expect(@ability).to be_able_to(:update, Goal.new(user_id: @manager.id, status: 0, team_id: nil)) }
      it { expect(@ability).to be_able_to(:update, Goal.new(user_id: @manager.id, status: 1, team_id: nil)) }
      it { expect(@ability).to be_able_to(:update, Goal.new(user_id: @manager.id, status: 3, team_id: nil)) }
      it { expect(@ability).not_to be_able_to(:update, Goal.new(user_id: @other_team_user.id, status: nil, team_id: nil)) }
      it { expect(@ability).to be_able_to(:destroy, Goal.new(user_id: @manager.id, status: nil, team_id: nil)) }
      it { expect(@ability).to be_able_to(:destroy, Goal.new(user_id: @manager.id, status: 0, team_id: nil)) }
      it { expect(@ability).to be_able_to(:destroy, Goal.new(user_id: @manager.id, status: 1, team_id: nil)) }
      it { expect(@ability).to be_able_to(:destroy, Goal.new(user_id: @manager.id, status: 3, team_id: nil)) }
      it { expect(@ability).not_to be_able_to(:destroy, Goal.new(user_id: @other_team_user.id, status: nil, team_id: nil)) }
      it { expect(@ability).to be_able_to(:create_from_template, Goal) }
      it { expect(@ability).to be_able_to(:new_template, Goal) }
      it { expect(@ability).to be_able_to(:create_template, Goal) }
      it { expect(@ability).to be_able_to(:new_from_template, Goal) }
      it { expect(@ability).to be_able_to(:read, Team.new(manager_id: @manager.id)) }
      it { expect(@ability).to be_able_to(:read, Team.new(id: @manager.team.team_id)) }
      it { expect(@ability).to be_able_to(:update, Team.new(manager_id: @manager.id)) }
      it { expect(@ability).not_to be_able_to(:read, Team.new(manager_id: @other_team_user.id)) }
      it { expect(@ability).not_to be_able_to(:update, Team.new(manager_id: @other_team_user.id)) }
      it { expect(@ability).not_to be_able_to(:manage, Category) }
    end
    context 'when is user' do
      before(:each) do
        @user = create(:user)
        @users_team = create(:team)
        @users_team.user_ids = @user.id 
        @other_user = create(:user)
        @other_users_team = create(:team)
        @other_users_team.user_ids = @other_user.id
        @ability = Ability.new(@user)
      end
      it { expect(@ability).to be_able_to(:create, Goal) }

      it { expect(@ability).to be_able_to(:read, Goal.new(is_template: true)) }
      it { expect(@ability).not_to be_able_to(:update, Goal.new(is_template: true)) }
      it { expect(@ability).not_to be_able_to(:destroy, Goal.new(is_template: true)) }
      # it { expect(@ability).not_to be_able_to(:destroy, Goal.new(user_id: @user.id, is_template_based: true)) }

      it { expect(@ability).to be_able_to(:read, Goal.new(user_id: @user.id, status: 2)) }
      it { expect(@ability).not_to be_able_to(:read, Goal.new(user_id: @other_user.id, status: 2)) }

      it { expect(@ability).to be_able_to(:read, Goal.new(team_id: @user.team.team_id, status: nil)) }
      it { expect(@ability).to be_able_to(:read, Goal.new(team_id: @user.team.team_id, status: 0)) }
      it { expect(@ability).to be_able_to(:read, Goal.new(team_id: @user.team.team_id, status: 1)) }
      it { expect(@ability).to be_able_to(:read, Goal.new(team_id: @user.team.team_id, status: 2)) }
      it { expect(@ability).to be_able_to(:read, Goal.new(team_id: @user.team.team_id, status: 3)) }
      it { expect(@ability).not_to be_able_to(:read, Goal.new(team_id: @other_users_team.id, status: nil)) }
      it { expect(@ability).not_to be_able_to(:read, Goal.new(team_id: @other_users_team.id, status: 0)) }
      it { expect(@ability).not_to be_able_to(:read, Goal.new(team_id: @other_users_team.id, status: 1)) }
      it { expect(@ability).not_to be_able_to(:read, Goal.new(team_id: @other_users_team.id, status: 2)) }
      it { expect(@ability).not_to be_able_to(:read, Goal.new(team_id: @other_users_team.id, status: 3)) }

      it { expect(@ability).to be_able_to(:read, Goal.new(team_id: @user.team.team_id, status: nil, is_template_based: true)) }
      it { expect(@ability).to be_able_to(:read, Goal.new(team_id: @user.team.team_id, status: 0, is_template_based: true)) }
      it { expect(@ability).to be_able_to(:read, Goal.new(team_id: @user.team.team_id, status: 1, is_template_based: true)) }
      it { expect(@ability).to be_able_to(:read, Goal.new(team_id: @user.team.team_id, status: 2, is_template_based: true)) }
      it { expect(@ability).to be_able_to(:read, Goal.new(team_id: @user.team.team_id, status: 3, is_template_based: true)) }
      it { expect(@ability).not_to be_able_to(:read, Goal.new(team_id: @other_users_team.id, status: nil, is_template_based: true)) }
      it { expect(@ability).not_to be_able_to(:read, Goal.new(team_id: @other_users_team.id, status: 0, is_template_based: true)) }
      it { expect(@ability).not_to be_able_to(:read, Goal.new(team_id: @other_users_team.id, status: 1, is_template_based: true)) }
      it { expect(@ability).not_to be_able_to(:read, Goal.new(team_id: @other_users_team.id, status: 2, is_template_based: true)) }
      it { expect(@ability).not_to be_able_to(:read, Goal.new(team_id: @other_users_team.id, status: 3, is_template_based: true)) }

      it { expect(@ability).to be_able_to(:update, Goal.new(user_id: @user.id, status: nil)) }
      it { expect(@ability).to be_able_to(:update, Goal.new(user_id: @user.id, status: 0)) }
      it { expect(@ability).to be_able_to(:update, Goal.new(user_id: @user.id, status: 1)) }
      it { expect(@ability).to be_able_to(:update, Goal.new(user_id: @user.id, status: 3)) }
      it { expect(@ability).not_to be_able_to(:update, Goal.new(user_id: @other_user.id, status: nil)) }
      it { expect(@ability).not_to be_able_to(:update, Goal.new(user_id: @other_user.id, status: 0)) }
      it { expect(@ability).not_to be_able_to(:update, Goal.new(user_id: @other_user.id, status: 1)) }
      it { expect(@ability).not_to be_able_to(:update, Goal.new(user_id: @other_user.id, status: 3)) }
      it { expect(@ability).to be_able_to(:destroy, Goal.new(user_id: @user.id, status: nil)) }
      it { expect(@ability).to be_able_to(:destroy, Goal.new(user_id: @user.id, status: 0)) }
      it { expect(@ability).to be_able_to(:destroy, Goal.new(user_id: @user.id, status: 1)) }
      it { expect(@ability).to be_able_to(:destroy, Goal.new(user_id: @user.id, status: 3)) }
      it { expect(@ability).not_to be_able_to(:destroy, Goal.new(user_id: @other_user.id, status: nil)) }
      it { expect(@ability).not_to be_able_to(:destroy, Goal.new(user_id: @other_user.id, status: 0)) }
      it { expect(@ability).not_to be_able_to(:destroy, Goal.new(user_id: @other_user.id, status: 1)) }
      it { expect(@ability).not_to be_able_to(:destroy, Goal.new(user_id: @other_user.id, status: 3)) }

      it { expect(@ability).not_to be_able_to(:update, Goal.new(user_id: @other_user.id, status: nil, team_id: @user.team.team_id)) }
      it { expect(@ability).not_to be_able_to(:destroy, Goal.new(user_id: @other_user.id, status: nil, team_id: @user.team.team_id)) }

      it { expect(@ability).to be_able_to(:create_from_template, Goal) }
      it { expect(@ability).to be_able_to(:new_from_template, Goal) }
      it { expect(@ability).not_to be_able_to(:new_template, Goal) }
      it { expect(@ability).not_to be_able_to(:create_template, Goal) }

      it { expect(@ability).to be_able_to(:read, Team.find_by(id: @users_team.id)) }
      it { expect(@ability).not_to be_able_to(:update, Team.find_by(id: @users_team.id)) }
      it { expect(@ability).not_to be_able_to(:destroy, Team.find_by(id: @users_team.id)) }
      it { expect(@ability).not_to be_able_to(:read, Team.find_by(id: @other_users_team.id)) }
      it 'is expected not to be able to read team if he has no team' do
        @new_user_with_no_team = create(:user)
        @ability = Ability.new(@new_user_with_no_team)
        expect(@ability).not_to be_able_to(:read, Team)
      end

      it { expect(@ability).not_to be_able_to(:manage, Category) }
    end
    context 'when has no role' do
      before(:each) do
        @user = create(:user)
        @no_role_user = create(:user, role: nil)
        @ability = Ability.new(@no_role_user)
      end
      it { expect(@ability).not_to be_able_to(:create, Goal) }
      it { expect(@ability).to be_able_to(:read, Goal.new(user_id: @no_role_user.id, status: 0)) }
      it { expect(@ability).to be_able_to(:read, Goal.new(user_id: @no_role_user.id, status: 1)) }
      it { expect(@ability).not_to be_able_to(:read, Goal.new(user_id: @user.id, status: 0)) }
      it { expect(@ability).not_to be_able_to(:manage, Team) }
      it { expect(@ability).not_to be_able_to(:manage, Category) }
    end
  end
end
