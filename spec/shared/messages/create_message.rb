RSpec.shared_examples 'POST /:id/messages' do
  describe 'POST /:id/messages' do
    let!(:campaign) { create(:campaign, creator: account) }
    let!(:session) { create(:session, account: account) }

    def app
      Controllers::Messages.new
    end

    describe 'Nominal case' do
      before do
        post "/campaigns/#{campaign.id}/messages", {token: gateway.token, app_key: appli.key, session_id: session.token, content: 'test'}
      end
      it 'Returns a Created (201) status code' do
        expect(last_response.status).to be 201
      end
      it 'Returns the correct body' do
        expect(last_response.body).to include_json({
          message: 'created',
          item: {
            username: account.username,
            type: 'text',
            data: {
              content: 'test'
            }
          }
        })
      end
      describe 'created message' do
        let!(:message) {
          campaign.reload
          campaign.messages.first
        }
        it 'has the correct message type' do
          expect(message.type).to eq :text
        end
        it 'has the correct content' do
          expect(message.data[:content]).to eq 'test'
        end
      end
    end

    it_should_behave_like 'a route', 'post', '/campaign_id/messages'

    describe '400 errors' do
      describe 'message not given' do
        before do
          post "/campaigns/#{campaign.id}/messages", {token: gateway.token, app_key: appli.key, session_id: session.token}
        end
        it 'Returns a Bad Request (400) status' do
          expect(last_response.status).to be 400
        end
        it 'Returns the correct body' do
          expect(JSON.parse(last_response.body)).to include_json({
            'status' => 400,
            'field' => 'content',
            'error' => 'required'
          })
        end
      end
      describe 'message given empty' do
        before do
          post "/campaigns/#{campaign.id}/messages", {token: gateway.token, app_key: appli.key, session_id: session.token, content: ''}
        end
        it 'Returns a Bad Request (400) status' do
          expect(last_response.status).to be 400
        end
        it 'Returns the correct body' do
          expect(JSON.parse(last_response.body)).to include_json({
            'status' => 400,
            'field' => 'content',
            'error' => 'required'
          })
        end
      end
      describe 'session ID not given' do
        before do
          post "/campaigns/#{campaign.id}/messages", {token: gateway.token, app_key: appli.key}
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
          post "/campaigns/#{campaign.id}/messages", {token: gateway.token, app_key: appli.key, session_id: session.token}
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
  end
end