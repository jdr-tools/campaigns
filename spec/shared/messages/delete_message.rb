RSpec.shared_examples 'DELETE /:id/messages/:message_id' do
  describe 'DELETE /:id/messages/:message_id' do
    let!(:campaign) { create(:campaign, creator: account) }
    let!(:session) { create(:session, account: account) }
    let!(:message) { create(:message, campaign: campaign, player: campaign.invitations.first, data: {content: 'test'}) }

    describe 'Nominal case' do
      before do
        delete "/campaigns/#{campaign.id.to_s}/messages/#{message.id.to_s}", {token: 'test_token', app_key: appli.key, session_id: session.token}
      end
      it 'Returns a OK (200) status code' do
        expect(last_response.status).to be 200
      end
      it 'Returns the correct body' do
        expect(last_response.body).to include_json({message: 'deleted'})
      end
      it 'has correctly marked the message as deleted' do
        message.reload
        expect(message.deleted).to be true
      end
    end

    it_should_behave_like 'a route', 'delete', '/campaign_id/messages/message_id'

    describe '403 errors' do
      describe 'When the user did not create the message' do
        let!(:other_account) { create(:account, username: 'other username', email: 'other@email.com') }
        let!(:invitation) { create(:accepted_invitation, account: other_account, campaign: campaign) }
        let!(:other_session) { create(:session, account: other_account, token: 'any other token') }

        before do
          delete "/campaigns/#{campaign.id.to_s}/messages/#{message.id.to_s}", {token: 'test_token', app_key: appli.key, session_id: other_session.token}
        end
        it 'Returns a Forbidden (403) status' do
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
      describe 'When the campaign does not exist' do
        before do
          delete "/campaigns/unknown/messages/#{message.id.to_s}", {token: 'test_token', app_key: appli.key, session_id: session.token}
        end
        it 'Returns a Not found (404) status' do
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
      describe 'When the message does not exist' do
        before do
          delete "/campaigns/#{campaign.id.to_s}/messages/unknown", {token: 'test_token', app_key: appli.key, session_id: session.token}
        end
        it 'Returns a Not found (404) status' do
          expect(last_response.status).to be 404
        end
        it 'Returns the correct body' do
          expect(JSON.parse(last_response.body)).to include_json({
            'status' => 404,
            'field' => 'message_id',
            'error' => 'unknown'
          })
        end
      end
    end
  end
end