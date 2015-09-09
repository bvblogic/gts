require 'rails_helper'

RSpec.describe GoalsController, type: :controller do
  let(:user) { create(:user, :admin) }
  before(:each) do
    sign_in user
  end
  describe "GET #show" do
    let(:goal) { create(:goal_with_children, user_id: user.id) }
    before(:each) do
      get :show, id: goal
    end
    it 'assigns the requested goal to @goal' do
      expect(assigns(:goal)).to eq goal
    end
    it 'assigns goals children to @scoped_collection if goal have them' do
      expect(assigns(:scoped_collection).count).to eq 2
    end
    it 'renders show_custom template if user have a permission' do
      expect(response).to render_template('show_custom')
    end
  end
  describe "GET #index" do
    let(:goal_list) { create_list(:goal, 6, user_id: user.id, team_id: nil) }
    it 'assigns scoped_collection to a default scope if no parameters where given' do
      get :index
      expect(assigns(:scoped_collection)).to match_array(goal_list)
    end
    it 'assigns scoped_collection to a certain scope if such was given in the parameters' do
      closed_list = create_list(:goal, 3, user_id: user.id, team_id: nil, status: 2)
      get :index, scope: :are_closed
      expect(assigns(:scoped_collection)).to match_array(closed_list)
    end
    it 'assigns scoped_collection to a search results if such was given in the parameters' do
      searched_goal = create(:goal, name: 'foo', team_id: nil, user_id: user.id)
      get :index, search: { name: 'foo' }
      expect(assigns(:scoped_collection)).to contain_exactly(searched_goal)
    end
    it 'renders index_custom' do
      get :index
      expect(response).to render_template('index_custom')
    end
  end
  describe "GET #edit" do
    let(:goal) { create(:goal_with_children, user_id: user.id) }
    before(:each) do
      get :edit, id: goal
    end
    it 'assigns the requested goal to @goal' do
      expect(assigns(:goal)).to eq goal
    end
    it 'renders edit_custom template if user have a permission' do
      expect(response).to render_template('edit_custom')
    end
  end
  describe "PATCH #update" do
    let(:goal) { create(:goal_with_children, user_id: user.id, team_id: nil) }
    context 'valid attributes' do
      before(:each) do
        patch :update, id: goal, goal: attributes_for(:goal, team_id: nil, status: "closed_succ")
      end 
      it 'assigns the requested goal to @goal' do
        expect(assigns(:goal)).to eq goal
      end
      it 'changes goals attributes' do
        goal.reload
        expect(goal.status).to eq 'closed_succ'
      end
      it 'redirects to main goals show page' do
        parent = find_parent(goal)
        expect(response).to redirect_to goal_path(parent)
      end
    end
    context 'unvalid attributes' do
      before(:each) do
        patch :update, id: goal, goal: attributes_for(:goal, team_id: nil, status: "closed_succ", name: nil)
      end
      it "does not change the goals attributes" do
        goal.reload
        expect(goal.name).not_to be_nil
      end
      it 're-renders the edit_custom template' do
        expect(response).to render_template('edit_custom')
      end
    end
  end
  describe "POST #create_template" do
    context 'valid attributes' do
      before(:each) do
        @category = create(:category)
        post :create_template, goal: attributes_for(:goal, team_id: nil, is_template: true, start_date: nil, end_date: nil, status: nil, category_ids: [@category.id])
      end
      it 'saves the goal' do
        expect{
                post :create_template, goal: attributes_for(:goal, team_id: nil, is_template: true, start_date: nil, end_date: nil, status: nil, category_ids: [@category.id])
              }.to change(Goal, :count).by(1)
      end
      it 'redirects to goals index page' do
        expect(response).to redirect_to(goals_path)
      end
    end 
    context 'unvalid attributes' do
      it "doesn't saves unvalid goal" do
        expect{
                post :create_template, goal: attributes_for(:goal, team_id: nil, is_template: true, start_date: nil, end_date: nil, status: nil)
              }.not_to change(Goal, :count)
      end
      it 'renders new_template' do
        post :create_template, goal: attributes_for(:goal, team_id: nil, is_template: true, start_date: nil, end_date: nil, status: nil)
        expect(response).to render_template('new_template')
      end
    end
  end
  describe "PATCH #create_from_template" do
    context 'valid attributes' do
      before(:each) do
        @template = create(:template)
        patch :create_from_template, id: @template, goal: attributes_for(:template, status: "open")
      end
      it 'saves the goal' do
        expect{
                patch :create_from_template, id: @template, goal: attributes_for(:template, status: "open")
              }.to change(Goal, :count).by(1)
      end
      it 'redirects to goals index page' do
        expect(response).to redirect_to(goals_path)
      end
    end
    context 'unvalid attributes' do
      before(:each) do
        @template = create(:template)
      end
      it 'does not save the goal' do
        expect{
                patch :create_from_template, id: @template, goal: attributes_for(:template, name: nil)
              }.not_to change(Goal, :count)
      end
      it 're-renders the goal_from_template page' do
        patch :create_from_template, id: @template, goal: attributes_for(:template, name: nil)
        expect(response).to render_template('goal_from_template')
      end
    end
  end
  describe "GET #close" do
    before(:each) do
      @request.env['HTTP_REFERER'] = 'http://localhost:3000/goals'
      @goal = create(:goal, team_id: nil, user_id: user.id, status: "in_progress")
      get :close, id: @goal
    end 
    it 'updates the status to closed_succ' do
      @goal.reload
      expect(@goal.status).to eq("closed_succ")
    end
    it 'redirects to back' do
      expect(response).to redirect_to(:back)
    end
  end
  describe "GET #add_substep" do
    before(:each) do
      @request.env['HTTP_REFERER'] = 'http://localhost:3000/goals'
      @goal = create(:goal, team_id: nil, user_id: user.id)
      xhr :get, :add_substep, id: @goal, format: :js
    end 
    it 'assigns requested goals id to @parent_id' do
      expect(assigns(:parent_id)).to eq(@goal.id)
    end
    it 'assigns new instance of goal to @goal' do
      expect(assigns(:goal)).to be_a_new(Goal)
    end
    it 'renders js' do
      expect(response.headers['Content-Type']).to match 'text/javascript'
    end
  end
  describe "POST create_substep" do
    before(:each) do |bfr|
      unless bfr.metadata[:skip_before]
        @request.env['HTTP_REFERER'] = 'http://localhost:3000/goals'
        @parent = create(:goal, team_id: nil, user_id: user.id)
        xhr :post, :create_substep, id: @parent, goal: attributes_for(:goal, parent_id: @parent.id, status: "open"), format: :js
      end
    end
    it 'assigns goal attributes to @goal' do
      expect(assigns(:goal)).to be_an_instance_of(Goal)
    end
    context 'request from index page' do
      before(:each) do
        @request.env['HTTP_REFERER'] = 'http://localhost:3000/goals'
      end
      it 'assigns scoped_collection to @scoped_collection' do
        goal = create(:goal, user_id: user.id, team_id: nil)
        expect(assigns(:scoped_collection)).to match_array([@parent, goal])
      end
    end
    context 'request from non-index page', :skip_before do
      it 'assigns goals sub goals to @scoped_collection' do
        @request.env['HTTP_REFERER'] = 'http://localhost:3000/goals/80'
        parent = create(:goal, user_id: user.id, team_id: nil)
        @goal = create(:goal, team_id: nil, user_id: user.id, parent_id: parent.id)
        xhr :post, :create_substep, id: @goal, goal: attributes_for(:goal, parent_id: parent.id, status: "open"), format: :js
        expect(assigns(:scoped_collection)).to match_array(parent.sub_goals)
      end
    end
    context 'valid attributes' do
      it 'saves the goal object', :skip_before do
        @request.env['HTTP_REFERER'] = 'http://localhost:3000/goals'
        @parent = create(:goal, team_id: nil, user_id: user.id)
        expect{
          xhr :post, :create_substep, id: @parent, goal: attributes_for(:goal, parent_id: @parent.id, status: "open"), format: :js
        }.to change(Goal, :count).by(1)
      end
      it 'renders js response' do
        expect(response.headers['Content-Type']).to match 'text/javascript'
      end
    end
    context 'unvalid attributes' do
      it "doesn't save the goal", :skip_before do
        @request.env['HTTP_REFERER'] = 'http://localhost:3000/goals'
        @parent = create(:goal, team_id: nil, user_id: user.id)
        expect{
          xhr :post, :create_substep, id: @parent, goal: attributes_for(:goal, parent_id: @parent.id, status: "open", name: nil), format: :js
        }.not_to change(Goal, :count)
      end
      it 'renders js response' do
        expect(response.headers['Content-Type']).to match 'text/javascript'
      end
    end
  end
  describe "POST #ajax_create_goal" do
    context 'valid attributes' do
      before(:each) do
        @parent = create(:goal, team_id: nil, user_id: user.id)
        xhr :post, :ajax_create_goal, id: @parent, goal: attributes_for(:goal, parent_id: @parent.id, status: "open"), format: :js
      end
      it 'assigns goal attributes to @goal' do
        expect(assigns(:goal)).to be_an_instance_of(Goal)
      end
      it 'assigns scoped_collection to @scoped_collection' do
        goal = create(:goal, user_id: user.id, team_id: nil)
        expect(assigns(:scoped_collection)).to match_array([@parent, goal])
      end
      it 'saves the goal' do
        expect{
                xhr :post, :ajax_create_goal, id: @parent, goal: attributes_for(:goal, parent_id: @parent.id, status: "open"), format: :js
              }.to change(Goal, :count).by(1)
      end
      it 'renders js response' do
        expect(response.headers['Content-Type']).to match 'text/javascript' 
      end
    end
    context 'unvalid attributes' do
      before(:each) do
        @parent = create(:goal, team_id: nil, user_id: user.id)
        xhr :post, :ajax_create_goal, id: @parent, goal: attributes_for(:goal, parent_id: @parent.id, status: "open"), format: :js
      end
      it "doesn't saves the goal" do
        expect{
                xhr :post, :ajax_create_goal, id: @parent, goal: attributes_for(:goal, parent_id: @parent.id, status: "open", name: nil), format: :js
              }.not_to change(Goal, :count)
      end
      it 'renders js response' do
        expect(response.headers['Content-Type']).to match 'text/javascript' 
      end
    end
  end
  describe "GET #custom_batch" do
    before(:each) do |bfr|
      unless bfr.metadata[:skip_before] 
        @request.env['HTTP_REFERER'] = 'http://localhost:3000/goals'
        create_list(:goal, 5, parent_id: nil, team_id: nil, user_id: user.id)
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
        @request.env['HTTP_REFERER'] = 'http://localhost:3000/goals'
        create_list(:goal, 5, parent_id: nil, team_id: nil, user_id: user.id)
        get :custom_batch, batch: { ids: Goal.all.pluck(:id), action_name: 'delete' }
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
