require 'rails_helper'

describe Api::V1::FeedsController, '#show', type: :api do
  describe 'Authorization' do
    context 'when not authenticated' do
      before do
        user = FactoryGirl.create(:user)

        get api_v1_user_feed_path(user.id), format: :json
      end

      it_returns_status(401)
      it_follows_json_schema('errors')
    end

    context 'when authenticated as a regular user' do
      before do
        user = create_and_sign_in_user
        5.times.collect{ FactoryGirl.create(:user) }.each do |u|
          5.times{ FactoryGirl.create(:micropost, user: u) }
          FactoryGirl.create(:relationship, follower: u, followed: user)
        end

        get api_v1_microposts_path, format: :json
      end

      it_returns_status(200)
      it_follows_json_schema('regular/microposts')
      it_returns_collection_size(resource: 'microposts', size: 5*5)
      it_returns_collection_attribute_values(
        resource: 'microposts', model: proc{Micropost.first!}, attrs: [
          :id, :content, :user_id, :created_at, :updated_at
        ],
        modifiers: {
          [:created_at, :updated_at] => proc{|i| i.in_time_zone('UTC').iso8601.to_s},
          id: proc{|i| i.to_s}
        }
      )
    end

    context 'when authenticated as an admin' do
      before do
        create_and_sign_in_admin_user
        user = FactoryGirl.create(:user)
        5.times.collect{ FactoryGirl.create(:user) }.each do |u|
          5.times{ FactoryGirl.create(:micropost, user: u) }
          FactoryGirl.create(:relationship, follower: u, followed: user)
        end

        get api_v1_microposts_path, format: :json
      end

      it_returns_status(200)
      it_follows_json_schema('admin/microposts')
      it_returns_collection_size(resource: 'microposts', size: 5*5)
      it_returns_collection_attribute_values(
        resource: 'microposts', model: proc{Micropost.first!}, attrs: [
          :id, :content, :user_id, :created_at, :updated_at
        ],
        modifiers: {
          [:created_at, :updated_at] => proc{|i| i.iso8601},
          id: proc{|i| i.to_s}
        }
      )
    end
  end
end
