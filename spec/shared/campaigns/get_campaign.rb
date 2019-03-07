RSpec.shared_examples 'Getting a campaign' do
  before do
    get "/campaigns/#{campaign.id.to_s}", {token: 'test_token', app_key: 'test_key', session_id: session.token}
  end
  it 'returns a OK (200) response code when successfully getting a camapign' do
    expect(last_response.status).to be 200
  end
  it 'returns the correct body when getting a campaign' do
    expect(JSON.parse(last_response.body)).to eq({
      'id' => campaign.id.to_s,
      'title' => campaign.title,
      'description' => campaign.description,
      'creator' => {
        'id' => campaign.creator.id.to_s,
        'username' => campaign.creator.username
      },
      'is_private' => campaign.is_private,
      'max_players' => campaign.max_players,
      'current_players' => campaign.invitations.where(enum_status: :accepted).count,
      'tags' => campaign.tags
    })
  end
end

RSpec.shared_examples 'GET /:id' do
  describe 'GET /:id' do
    let!(:campaign) { create(:campaign, creator: account) }

    describe 'Nominal case' do
      let!(:session) { create(:session, account: account) }

      include_examples 'Getting a campaign'
    end

    describe 'Alternative cases' do
      let!(:another_account) { create(:account) }
      let!(:session) { create(:session, account: another_account) }
      
      describe 'The requester has a pending invitation' do
        let!(:invitation) { create(:pending_invitation, account: another_account, campaign: campaign)}
        
        include_examples 'Getting a campaign'
      end
      describe 'The request has an accepted invitation' do
        let!(:invitation) { create(:accepted_invitation, account: another_account, campaign: campaign)}
      
        include_examples 'Getting a campaign'
      end
    end

    it_should_behave_like 'a route', 'get', '/campaign_id'

    describe '400 errors' do
      describe 'session ID not given' do
        before do
          get '/campaigns/campaign_id', {token: 'test_token', app_key: 'test_key'}
        end
        it 'Returns a Bad Request (400) status' do
          expect(last_response.status).to be 400
        end
        it 'Returns the correct body' do
          expect(JSON.parse(last_response.body)).to include_json({
            'status' => 400,
            'field' => 'session_id',
            'error' => 'required'
          })
        end
      end
    end

    describe '403 error' do
      describe 'Session ID not allowed' do
        let!(:another_account) { create(:account) }
        let!(:session) { create(:session, account: another_account) }

        before do
          get '/campaigns/campaign_id', {token: 'test_token', app_key: 'test_key', session_id: session.token}
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

    describe '404 Errors' do
      describe 'Campaign not found' do
        let!(:session) { create(:session, account: account) }
        
        before do
          get '/campaigns/fake_campaign_id', {token: 'test_token', app_key: 'test_key', session_id: session.token}
        end
        it 'Returns a Not Found (404) status' do
          expect(last_response.status).to be 404
        end
        it 'Returns the correct body' do
          expect(JSON.parse(last_response.body)).to include_json({
            'status' => 404,
            'field' => 'campaign_id',
            'error' => 'unknown'
          })
        end
      end

      describe 'Session not found' do
        let!(:session) { create(:session, account: account) }
        
        before do
          get '/campaigns/campaign_id', {token: 'test_token', app_key: 'test_key', session_id: 'fake_token'}
        end
        it 'Returns a Not Found (404) status' do
          expect(last_response.status).to be 404
        end
        it 'Returns the correct body' do
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