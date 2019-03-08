RSpec.shared_examples 'GET /' do
  describe 'GET /' do
    # The campaign must be public to be displayed in the list of public campaign.
    let!(:campaign) { create(:campaign, creator: account, is_private: false) }

    # This other campaign is here to check if a campaign created by an account is NOT returned to this account.
    let!(:other_account) { create(:account, username: 'other_username', email: 'other@mail.com') }
    let!(:other_campaign) { create(:campaign, id: 'other_campaign_id', creator: other_account, title: 'another title', is_private: false) }

    # Session of the account asking for his custom list of public campaigns.
    let!(:session) { create(:session, account: account) }

    describe 'Campaign without invitation' do
      before do
        get '/campaigns', {token: 'test_token', app_key: appli.key, session_id: session.token}
      end
      it 'correctly returns a OK (200) status' do
        expect(last_response.status).to be 200
      end
      it 'returns the correct body' do
        expect(JSON.parse(last_response.body)).to eq({
          'count' => 1,
          'items' => [
            {
              'id' => other_campaign.id.to_s,
              'title' => 'another title',
              'description' => 'A longer description of the campaign',
              'creator' => {
                'id' => other_account.id.to_s,
                'username' => 'other_username'
              },
              'invitation' => nil,
              'is_private' => false,
              'max_players' => 5,
              'current_players' => 0,
              'tags' => ['test_tag']
            }
          ]
        })
      end
    end
    describe 'Campaign with pending invitation' do
      let!(:invitation) { create(:pending_invitation, campaign: 'other_campaign_id', account: account) }

      before do
        get '/campaigns', {token: 'test_token', app_key: appli.key, session_id: session.token}
      end
      it 'correctly returns a OK (200) status' do
        expect(last_response.status).to be 200
      end
      it 'returns the correct body' do
        expect(JSON.parse(last_response.body)).to eq({
          'count' => 1,
          'items' => [
            {
              'id' => other_campaign.id.to_s,
              'title' => 'another title',
              'description' => 'A longer description of the campaign',
              'creator' => {
                'id' => other_account.id.to_s,
                'username' => 'other_username'
              },
              'invitation' => {
                'id' => invitation.id.to_s,
                'created_at' => invitation.created_at.utc.iso8601,
                'status' => 'pending'
              },
              'is_private' => false,
              'max_players' => 5,
              'current_players' => 0,
              'tags' => ['test_tag']
            }
          ]
        })
      end
    end
    describe 'Campaign with request invitation' do
      let!(:invitation) { create(:request_invitation, campaign: 'other_campaign_id', account: account) }
      
      before do
        get '/campaigns', {token: 'test_token', app_key: appli.key, session_id: session.token}
      end
      it 'correctly returns a OK (200) status' do
        expect(last_response.status).to be 200
      end
      it 'returns the correct body' do
        expect(JSON.parse(last_response.body)).to eq({
          'count' => 1,
          'items' => [
            {
              'id' => other_campaign.id.to_s,
              'title' => 'another title',
              'description' => 'A longer description of the campaign',
              'creator' => {
                'id' => other_account.id.to_s,
                'username' => 'other_username'
              },
              'invitation' => {
                'id' => invitation.id.to_s,
                'created_at' => invitation.created_at.utc.iso8601,
                'status' => 'request'
              },
              'is_private' => false,
              'max_players' => 5,
              'current_players' => 0,
              'tags' => ['test_tag']
            }
          ]
        })
      end
    end
    describe 'Campaign with accepted invitation' do
      let!(:invitation) { create(:accepted_invitation, campaign: 'other_campaign_id', account: account) }
      
      before do
        get '/campaigns', {token: 'test_token', app_key: appli.key, session_id: session.token}
      end
      it 'correctly returns a OK (200) status' do
        expect(last_response.status).to be 200
      end
      it 'returns the correct body' do
        expect(JSON.parse(last_response.body)).to eq({
          'count' => 1,
          'items' => [
            {
              'id' => other_campaign.id.to_s,
              'title' => 'another title',
              'description' => 'A longer description of the campaign',
              'creator' => {
                'id' => other_account.id.to_s,
                'username' => 'other_username'
              },
              'invitation' => {
                'id' => invitation.id.to_s,
                'created_at' => invitation.created_at.utc.iso8601,
                'status' => 'accepted'
              },
              'is_private' => false,
              'max_players' => 5,
              'current_players' => 1,
              'tags' => ['test_tag']
            }
          ]
        })
      end
    end
    describe 'Campaign with left invitation' do
      let!(:invitation) { create(:left_invitation, campaign: 'other_campaign_id', account: account) }
      
      before do
        get '/campaigns', {token: 'test_token', app_key: appli.key, session_id: session.token}
      end
      it 'correctly returns a OK (200) status' do
        expect(last_response.status).to be 200
      end
      it 'returns the correct body' do
        expect(JSON.parse(last_response.body)).to eq({
          'count' => 1,
          'items' => [
            {
              'id' => other_campaign.id.to_s,
              'title' => 'another title',
              'description' => 'A longer description of the campaign',
              'creator' => {
                'id' => other_account.id.to_s,
                'username' => 'other_username'
              },
              'invitation' => nil,
              'is_private' => false,
              'max_players' => 5,
              'current_players' => 0,
              'tags' => ['test_tag']
            }
          ]
        })
      end
    end
    describe 'Campaign with expelled invitation' do
      let!(:invitation) { create(:expelled_invitation, campaign: 'other_campaign_id', account: account) }
      
      before do
        get '/campaigns', {token: 'test_token', app_key: appli.key, session_id: session.token}
      end
      it 'correctly returns a OK (200) status' do
        expect(last_response.status).to be 200
      end
      it 'returns the correct body' do
        expect(JSON.parse(last_response.body)).to eq({
          'count' => 1,
          'items' => [
            {
              'id' => other_campaign.id.to_s,
              'title' => 'another title',
              'description' => 'A longer description of the campaign',
              'creator' => {
                'id' => other_account.id.to_s,
                'username' => 'other_username'
              },
              'invitation' => nil,
              'is_private' => false,
              'max_players' => 5,
              'current_players' => 0,
              'tags' => ['test_tag']
            }
          ]
        })
      end
    end
    describe 'Campaign with refused invitation' do
      let!(:invitation) { create(:refused_invitation, campaign: 'other_campaign_id', account: account) }
      
      before do
        get '/campaigns', {token: 'test_token', app_key: appli.key, session_id: session.token}
      end
      it 'correctly returns a OK (200) status' do
        expect(last_response.status).to be 200
      end
      it 'returns the correct body' do
        expect(JSON.parse(last_response.body)).to eq({
          'count' => 1,
          'items' => [
            {
              'id' => other_campaign.id.to_s,
              'title' => 'another title',
              'description' => 'A longer description of the campaign',
              'creator' => {
                'id' => other_account.id.to_s,
                'username' => 'other_username'
              },
              'invitation' => nil,
              'is_private' => false,
              'max_players' => 5,
              'current_players' => 0,
              'tags' => ['test_tag']
            }
          ]
        })
      end
    end
    
    describe 'Campaign with blocked invitation' do
      let!(:invitation) { create(:blocked_invitation, campaign: 'other_campaign_id', account: account) }
      
      before do
        get '/campaigns', {token: 'test_token', app_key: appli.key, session_id: session.token}
      end
      it 'correctly returns a OK (200) status' do
        expect(last_response.status).to be 200
      end
      it 'returns the correct body' do
        expect(JSON.parse(last_response.body)).to eq({'count' => 0, 'items' => []})
      end
    end

    describe 'Campaign with ignored invitation' do
      let!(:invitation) { create(:ignored_invitation, campaign: 'other_campaign_id', account: account) }
      
      before do
        get '/campaigns', {token: 'test_token', app_key: appli.key, session_id: session.token}
      end
      it 'correctly returns a OK (200) status' do
        expect(last_response.status).to be 200
      end
      it 'returns the correct body' do
        expect(JSON.parse(last_response.body)).to eq({
          'count' => 1,
          'items' => [
            {
              'id' => other_campaign.id.to_s,
              'title' => 'another title',
              'description' => 'A longer description of the campaign',
              'creator' => {
                'id' => other_account.id.to_s,
                'username' => 'other_username'
              },
              'invitation' => {
                'id' => invitation.id.to_s,
                'created_at' => invitation.created_at.utc.iso8601,
                'status' => 'ignored'
              },
              'is_private' => false,
              'max_players' => 5,
              'current_players' => 0,
              'tags' => ['test_tag']
            }
          ]
        })
      end
    end

    it_should_behave_like 'a route', 'get', '/campaigns'
  end
end