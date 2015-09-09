FactoryGirl.define do
  factory :goal do
    association :user, factory: :user
    association :team, factory: :team
    name Faker::Company.name
    description Faker::Lorem.paragraph
    start_date Date.today
    end_date  Date.tomorrow
    status 0
    image { Rack::Test::UploadedFile.new(File.join(Rails.root, 'spec', 'support', 'logos', 'delete.png')) }
    is_template false
    is_template_based false
    team_id = nil
    after(:build) do |goal|
      category1 = create(:category) 
      category2 = create(:category)
      goal.category_ids = [category1.id, category2.id]
    end
    factory :goal_with_children do
      after(:create) do |goal|
        create_list(:goal, 2, parent_id: goal.id, user_id: goal.user_id)
      end
    end
    factory :template do
      is_template true
      start_date nil
      end_date nil
      status nil
      team nil
    end
  end
end