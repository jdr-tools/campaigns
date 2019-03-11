RSpec.shared_examples 'DELETE /:id' do
  describe 'DELETE /:id' do
    let!(:other_account) { create(:account, username: 'Other username', email: 'test@email.com') }
    let!(:campaign) { create(:campaign, creator: account) }
    let!(:invitation) { create(:accepted_invitation, campaign: campaign, account: other_account) }
    let!(:session) { create(:session, account: account) }
    let!(:base_64_content) {'data:text/plain;base64,dGVzdApzYXV0IGRlIGxpZ25lIGV0IGVzcGFjZXM='}

    describe 'Nominal case' do
      before do
        post "/campaigns/#{campaign.id.to_s}/files", {
          session_id: session.token,
          app_key: appli.key,
          token: gateway.token,
          name: 'test.txt',
          content: base_64_content
        }

        delete "/campaigns/#{campaign.id}", {token: gateway.token, app_key: appli.key, session_id: session.token}
      end
      it 'Returns a OK (200) when you successfully delete a campaign' do
        expect(last_response.status).to be 200
      end
      it 'Returns the correct body when successfully suppressing a campaign' do
        expect(JSON.parse(last_response.body)).to eq({'message' => 'deleted'})
      end
      it 'has deleted the campaign properly' do
        expect(Arkaan::Campaign.count).to be 0
      end
      it 'has deleted the invitation properly' do
        expect(Arkaan::Campaigns::Invitation.count).to be 0
      end
      it 'has deleted the file properly' do
        expect(Arkaan::Campaigns::File.all.count).to be 0
      end
    end

    it_should_behave_like 'a route', 'delete', '/campaign_id'

    describe '400 errors' do
      describe 'session ID not given' do
        before do
          get '/campaigns/own', {token: gateway.token, app_key: appli.key}
        end
        it 'Raises a Bad Request (400) error' do
          expect(last_response.status).to be 400
        end
        it 'Returns the correct body' do
          expect(last_response.body).to include_json({
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
        let!(:another_session) { create(:session, account: another_account) }

        before do
          get "/campaigns/#{campaign.id}", {token: gateway.token, app_key: appli.key, session_id: another_session.token}
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
      describe 'session ID not found' do
        before do
          get '/campaigns/own', {token: gateway.token, app_key: appli.key, session_id: 'unknown_session_id'}
        end
        it 'Raises a Not Found (404)) error' do
          expect(last_response.status).to be 404
        end
        it 'Returns the correct body' do
          expect(last_response.body).to include_json({
            'status' => 404,
            'field' => 'session_id',
            'error' => 'unknown'
          })
        end
      end

      describe 'Campaign not found error' do
        let!(:another_account) { create(:account) }
        let!(:another_session) { create(:session, account: another_account) }

        before do
          delete '/campaigns/any_other_id', {token: gateway.token, app_key: appli.key, session_id: another_session.token}
        end
        it 'correctly returns a Not Found (404) error when the campaign you try to delete does not exist' do
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
    end
  end
end