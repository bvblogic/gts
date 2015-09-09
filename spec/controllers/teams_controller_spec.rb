require 'rails_helper'

RSpec.describe TeamsController, type: :controller do
  let(:team) { create(:team) }
  let(:user) { create(:user) }
  let(:admin) { create(:user, :admin) }
  let(:users_array) { [user, admin] }
  before(:each) do
    sign_in admin
  end

  describe "GET #show" do
    before(:each) do
      get :show, id: team.id
    end
    it 'returns assigns team' do
      expect(assigns(:team)).to eq(team)
    end
    it 'renders template :custom_show' do
      expect(response).to render_template('custom_show')
    end
  end
  describe "GET #edit" do
    before(:each) do
      get :edit, id: team.id
    end
    it "returns assigns @team" do
      expect(assigns(:team)).to eq(team)
    end
    it "renders custom_edit" do
      expect(response).to render_template('custom_edit')
    end
  end
  describe "PATCH #update" do
    context 'valid attributes' do
      before(:each) do
        patch :update, id: team.id, team: attributes_for(:team, name: 'foo')
      end 
      it 'assigns the requested team to @team' do
        expect(assigns(:team)).to eq team
      end
      it 'changes teams attributes' do
        team.reload
        expect(team.name).to eq 'foo'
      end
      it 'redirects to teams show page' do
        expect(response).to redirect_to team_path(team)
      end
    end
    context 'unvalid attributes' do
      before(:each) do
        patch :update, id: team.id, team: attributes_for(:team, manager_id: nil)
      end
      it "does not change the teams attributes" do
        team.reload
        expect(team.manager).not_to be_nil
      end
      it 're-renders the edit_custom template' do
        expect(response).to render_template('custom_edit')
      end
    end
  end
  describe 'GET #index' do
    let(:teams) { create_list(:team, 2) }
    it 'assigns users teams to a scoped_collection if no parameters where given' do
      get :index
      expect(assigns(:scoped_collection)).to match_array(teams)
    end
    it 'assigns scoped_collection to a search results if such was given in the parameters' do
      searched_team = create(:team, name: 'foo')
      get :index, search: { name: searched_team.id }.with_indifferent_access
      expect(assigns(:scoped_collection)).to contain_exactly(searched_team)
    end
    it 'renders index_custom' do
      get :index
      expect(response).to render_template('custom_index')
    end
  end
  describe "GET #custom_batch" do
    before(:each) do |bfr|
      unless bfr.metadata[:skip_before] 
        @request.env['HTTP_REFERER'] = 'http://localhost:3000/teams'
        create_list(:team, 5)
        get :custom_batch, batch: { ids: [], action_name: 'delete' }  
      end
    end
    context 'without ids' do
      it 'flashes warning if ids array is empty' do
        expect(controller).to set_flash[:warning]
      end
      it 'redirects to back' do
        expect(response).to redirect_to(:back)
      end
    end
    context 'with ids', :skip_before do
      before(:each) do
        @request.env['HTTP_REFERER'] = 'http://localhost:3000/teams'
        create_list(:team, 5)
        get :custom_batch, batch: { ids: Team.all.pluck(:id), action_name: 'delete' }
      end
      it 'flashes success if ids are present' do
        expect(controller).to set_flash[:success]
      end
      it 'redirects to back' do
        expect(response).to redirect_to(:back)
      end
    end
  end
end
