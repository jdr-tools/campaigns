RSpec.shared_examples 'PUT /:id' do
  describe 'PUT /:id' do
    let!(:campaign) { create(:campaign, creator: account, max_players: 4) }
    let!(:counter) { Arkaan::Campaigns::Tag.create(content: 'test_tag', count: 1) }
    let!(:session) { create(:session, account: account) }

    describe 'Successful updates' do

      describe 'nothing being updated' do
        before do
          put "/campaigns/#{campaign.id.to_s}", {token: 'test_token', app_key: appli.key, session_id: session.token}
        end
        it 'returns a OK (200) response code when updating nothing' do
          expect(last_response.status).to be 200
        end
        it 'returns the correct body when updating nothing' do
          expect(JSON.parse(last_response.body)).to eq({'message' => 'updated'})
        end
        describe 'campaign parameters' do
          let!(:updated_campaign) { Arkaan::Campaign.where(id: campaign.id).first }

          it 'has not changed the title of the campaign' do
            expect(updated_campaign.title).to eq campaign.title
          end
          it 'has not changed the description of the campaign' do
            expect(updated_campaign.description).to eq 'A longer description of the campaign'
          end
          it 'has not changed the privacy of the campaign' do
            expect(updated_campaign.is_private).to be true
          end
          it 'has not changed the maximum number of players' do
            expect(updated_campaign.max_players).to be 4
          end
          it 'has not changed the tags of the campaign' do
            expect(updated_campaign.tags).to eq ['test_tag']
          end
        end
      end
      describe 'update of the title' do
        before do
          put "/campaigns/#{campaign.id.to_s}", {token: 'test_token', app_key: appli.key, title: 'another random title', session_id: session.token}
        end
        it 'returns a OK (200) response code when updating the title' do
          expect(last_response.status).to be 200
        end
        it 'returns the right body when updating the title' do
          expect(JSON.parse(last_response.body)).to eq({'message' => 'updated'})
        end
        it 'has correctly updated the title of the campaign' do
          expect(Arkaan::Campaign.where(id: campaign.id).first.title).to eq 'another random title'
        end
      end
      describe 'update of the description' do
        before do
          put "/campaigns/#{campaign.id.to_s}", {token: 'test_token', app_key: appli.key, description: 'another long description', session_id: session.token}
        end
        it 'returns a OK (200) response code when updating the description' do
          expect(last_response.status).to be 200
        end
        it 'returns the right body when updating the description' do
          expect(JSON.parse(last_response.body)).to eq({'message' => 'updated'})
        end
        it 'has correctly updated the description of the campaign' do
          expect(Arkaan::Campaign.where(id: campaign.id).first.description).to eq 'another long description'
        end
      end
      describe 'update of the privacy' do
        before do
          put "/campaigns/#{campaign.id.to_s}", {token: 'test_token', app_key: appli.key, is_private: false, session_id: session.token}
        end
        it 'returns a OK (200) response code when updating the privacy' do
          expect(last_response.status).to be 200
        end
        it 'returns the right body when updating the privacy' do
          expect(JSON.parse(last_response.body)).to eq({'message' => 'updated'})
        end
        it 'has correctly updated the privacy of the campaign' do
          expect(Arkaan::Campaign.where(id: campaign.id).first.is_private).to be false
        end
      end
      describe 'update of the max players' do
        before do
          put "/campaigns/#{campaign.id.to_s}", {token: 'test_token', app_key: appli.key, max_players: 10, session_id: session.token}
        end
        it 'returns a OK (200) response code when updating the privacy' do
          expect(last_response.status).to be 200
        end
        it 'returns the right body when updating the privacy' do
          expect(JSON.parse(last_response.body)).to eq({'message' => 'updated'})
        end
        it 'has correctly updated the privacy of the campaign' do
          expect(Arkaan::Campaign.where(id: campaign.id).first.max_players).to be 10
        end
      end
      describe 'update of the tags' do
        describe 'update with an empty tags list' do
          before do
            put "/campaigns/#{campaign.id.to_s}", {token: 'test_token', app_key: appli.key, tags: [], session_id: session.token}
          end
          it 'returns a OK (200) response code when updating the tags' do
            expect(last_response.status).to be 200
          end
          it 'returns the right body when updating the tags' do
            expect(JSON.parse(last_response.body)).to eq({'message' => 'updated'})
          end
          it 'has correctly updated the tags of the campaign' do
            expect(Arkaan::Campaign.where(id: campaign.id).first.tags).to eq []
          end
          it 'has deleted the tags counters not used anymore' do
            expect(Arkaan::Campaigns::Tag.all.count).to be 0
          end
        end
        describe 'update with another tags list' do
          before do
            put "/campaigns/#{campaign.id.to_s}", {token: 'test_token', app_key: appli.key, tags: ['random_tag'], session_id: session.token}
          end
          it 'returns a OK (200) response code when updating the tags' do
            expect(last_response.status).to be 200
          end
          it 'returns the right body when updating the tags' do
            expect(JSON.parse(last_response.body)).to eq({'message' => 'updated'})
          end
          it 'has correctly updated the tags of the campaign' do
            expect(Arkaan::Campaign.where(id: campaign.id).first.tags).to eq ['random_tag']
          end
          it 'has left only one counter for tags' do
            expect(Arkaan::Campaigns::Tag.all.count).to be 1
          end
          it 'has left a tags counter with the right content' do
            expect(Arkaan::Campaigns::Tag.first.content).to eq 'random_tag'
          end
          it 'has left a tags counter with the right count' do
            expect(Arkaan::Campaigns::Tag.first.count).to be 1
          end
        end
      end
    end

    it_should_behave_like 'a route', 'put', '/campaign_id'

    describe '400 errors' do
      describe 'session ID not given' do
        before do
          put "/campaigns/#{campaign.id}", {token: 'test_token', app_key: appli.key, title: 'another title'}
        end
        it 'returns an Unprocessable Entity (400) response code when updating with an already used title' do
          expect(last_response.status).to be 400
        end
        it 'returns the correct body when updating with an already used title' do
          expect(JSON.parse(last_response.body)).to include_json({
            'status' => 400,
            'field' => 'session_id',
            'error' => 'required'
          })
        end
      end

      describe 'when the updated title is already used by another campaign' do
        let!(:campaign) { create(:campaign, creator: account) }
        let!(:other_campaign) { create(:campaign, id: 'another_campaign_id', title: 'another title', creator: account) }

        before do
          put "/campaigns/#{campaign.id}", {token: 'test_token', app_key: appli.key, title: 'another title', session_id: session.token}
        end
        it 'returns an 400 status' do
          expect(last_response.status).to be 400
        end
        it 'returns the correct body' do
          expect(JSON.parse(last_response.body)).to include_json({
            'status' => 400,
            'field' => 'title',
            'error' => 'uniq'
          })
        end
      end
    end

    describe '403 error' do
      describe 'Session ID not allowed' do
        let!(:another_account) { create(:account) }
        let!(:another_session) { create(:session, account: another_account) }

        before do
          get "/campaigns/#{campaign.id}", {token: 'test_token', app_key: appli.key, session_id: another_session.token}
        end
        it 'Returns a 403 error' do
          expect(last_response.status).to be 403
        end
        it 'Returns the correct body' do
          expect(JSON.parse(last_response.body)).to include_json({
            'status' => 403,
            'field' => 'session_id',
            'error' => 'forbidden'
          })
        end
      end
    end

    describe '404 errors' do
      describe 'Campaign not found' do
        before do
          put '/campaigns/fake_campaign_id', {token: 'test_token', app_key: appli.key, session_id: session.token}
        end
        it 'correctly returns a Not Found (404) error when the campaign you want to update does not exist' do
          expect(last_response.status).to be 404
        end
        it 'returns the correct body when the campaign does not exist' do
          expect(JSON.parse(last_response.body)).to include_json({
            'status' => 404,
            'field' => 'campaign_id',
            'error' => 'unknown'
          })
        end
      end

      describe 'Session not found' do
        before do
          put "/campaigns/#{campaign.id}", {token: 'test_token', app_key: appli.key, session_id: 'unknown_token'}
        end
        it 'correctly returns a Not Found (404) error when the campaign you want to update does not exist' do
          expect(last_response.status).to be 404
        end
        it 'returns the correct body when the campaign does not exist' do
          expect(JSON.parse(last_response.body)).to include_json({
            'status' => 404,
            'field' => 'session_id',
            'error' => 'unknown'
          })
        end
      end
    end
  end
end