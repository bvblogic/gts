FactoryGirl.define do
  factory :user do
    sequence(:name) { |n| "Ivane-#{n}" } 
    sequence(:email) { |n| "bububu#{n}@gmail.com" }
    password "password"
    password_confirmation "password"
    role 0
    trait :admin do
      role 1
    end
    factory :user_with_teams do
      transient do
        teams_count 4
      end
      after(:create) do |user, evaluator|
        create_list(:team, evaluator.teams_count, manager_id: user.id)
      end
    end
  end
end