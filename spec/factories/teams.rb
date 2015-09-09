FactoryGirl.define do
  factory :team do
    association :manager, factory: :user
    sequence(:name) { |n| "Team-#{n}" } 
    after(:build) do |team|
      user1 = create(:user) 
      user2 = create(:user)
      team.user_ids = [user1.id, user2.id]
    end
  end
end