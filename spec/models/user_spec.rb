require 'rails_helper'
require "cancan/matchers"

RSpec.describe User, type: :model do

  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_uniqueness_of(:name) }
  it { is_expected.to validate_length_of(:password) }
  it { is_expected.to have_many(:teams) }
  it { is_expected.to have_one(:team) }

  describe "admin" do
    let(:admin_user){ FactoryGirl.create(:user, :admin) }
    specify { expect(admin_user.role).to eq('admin') }
  end

end
