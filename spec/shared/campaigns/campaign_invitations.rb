RSpec.shared_examples 'GET /:id/invitations' do

  describe 'GET /:id/invitations' do
    let!(:other_account) { create(:account) }
    let!(:third_account) { create(:account) }
    let!(:campaign) { create(:campaign, creator: account) }
    let!(:pending_invitation) { create(:invitation, account: third_account, campaign: campaign) }
    let!(:accepted_invitation) { create(:accepted_invitation, account: other_account, campaign: campaign) }
    let!(:session) { create(:session, account: account) }

    def app
      Controllers::Invitations.new
    end

    describe 'Nominal case' do
      before do
        get "/campaigns/#{campaign.id}/invitations", {token: 'test_token', app_key: 'test_key', session_id: session.token}
      end
      it 'Returns a OK (200) status code when correctly returning the invitations' do
        expect(last_response.status).to be 200
      end
      it 'Returns the correct invitations when getting the invitations' do
        expect(last_response.body).to match_unordered_json([
          {
            'id' => campaign.invitations.where(enum_status: :creator).first.id.to_s,
            'status' => 'creator',
            'username' => account.username
          },
          {
            'id' => pending_invitation.id.to_s,
            'status' => 'pending',
            'username' => third_account.username
          },
          {
            'id' => accepted_invitation.id.to_s,
            'status' => 'accepted',
            'username' => other_account.username
          }
        ])
      end
    end

    it_should_behave_like 'a route', 'get', '/campaigns/campaign_id/invitations'

    describe '400 errors' do
      describe 'session ID not given' do
        before do
          get "/campaigns/#{campaign.id}/invitations", {token: 'test_token', app_key: 'test_key'}
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
          get "/campaigns/#{campaign.id}/invitations", {token: 'test_token', app_key: 'test_key', session_id: session.token}
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

    describe 'Not Found Errors' do
      describe 'Campaign not found error' do
        before do
          get '/campaigns/fake_campaign_id/invitations', {token: 'test_token', app_key: 'test_key', session_id: session.token}
        end
        it 'correctly returns a Not Found (404) error when the campaign you want to get does not exist' do
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
        let!(:session) { create(:session, account: account) }
        
        before do
          get "/campaigns/#{campaign.id}/invitations", {token: 'test_token', app_key: 'test_key', session_id: 'fake_token'}
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