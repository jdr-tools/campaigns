RSpec.shared_examples 'GET /:id/messages' do
  describe 'GET /:id/messages' do
    let!(:campaign) { create(:campaign, creator: account) }
    let!(:another_account) { create(:account) }
    let!(:session) { create(:session, account: another_account) }
    let!(:chat_invitation) { create(:accepted_invitation, campaign: campaign, account: another_account) }
    let!(:message) { create(:message, player: chat_invitation, campaign: campaign) }

    def app
      Controllers::Messages.new
    end

    describe 'Nominal case' do
      before do
        get "/campaigns/#{campaign.id.to_s}/messages", {token: gateway.token, app_key: appli.key, session_id: session.token}
      end
      it 'Returns a OK (200) status code' do
        expect(last_response.status).to be 200
      end
      it 'Retuens the correct body' do
        expect(last_response.body).to include_json([
          {
            id: message.id.to_s,
            username: another_account.username,
            created_at: message.created_at.utc.iso8601,
            type: 'text',
            data: {
              content: 'test messages'
            }
          }
        ])
      end
    end

    describe 'Alternative cases' do
      let!(:third_account) { create(:account, username: 'test_user_3', email: 'test3@mail.com') }
      let!(:third_session) { create(:session, account: third_account, token: 'yet_another_token') }
      let!(:third_invitation) { create(:accepted_invitation, campaign: campaign, account: third_account) }
      let!(:admin_session) { create(:session, account: campaign.creator, token: 'admin_session_token') }

      describe 'Public dice rolls' do
        let!(:roll_dice) {
          message = build(:message, enum_type: :command, player: third_invitation, data: {
            command: 'roll',
            number_of_dices: 1,
            number_of_faces: 20,
            modifier: 2,
            results: [16]
          })
          campaign.messages = [message]
          campaign.save
          message
        }

        describe 'For the sender of the message' do
          before do
            get "/campaigns/#{campaign.id.to_s}/messages", {token: gateway.token, app_key: appli.key, session_id: third_session.token}
          end
          it 'Returns a 200 (OK) status code' do
            expect(last_response.status).to be 200
          end
          it 'Returns the correct body' do
            expect(last_response.body).to include_json([
              {
                type: 'command',
                username: 'test_user_3',
                data: {
                  command: 'roll',
                  number_of_dices: 1,
                  number_of_faces: 20,
                  modifier: 2,
                  results: [16]
                }
              }
            ])
          end
        end
        describe 'For another player' do
          before do
            get "/campaigns/#{campaign.id.to_s}/messages", {token: gateway.token, app_key: appli.key, session_id: session.token}
          end
          it 'Returns a 200 (OK) status code' do
            expect(last_response.status).to be 200
          end
          it 'Returns the correct body' do
            expect(last_response.body).to include_json([
              {
                type: 'command',
                username: 'test_user_3',
                data: {
                  command: 'roll',
                  number_of_dices: 1,
                  number_of_faces: 20,
                  modifier: 2,
                  results: [16]
                }
              }
            ])
          end
        end
        describe 'For the game master' do
          before do
            get "/campaigns/#{campaign.id.to_s}/messages", {token: gateway.token, app_key: appli.key, session_id: admin_session.token}
          end
          it 'Returns a 200 (OK) status code' do
            expect(last_response.status).to be 200
          end
          it 'Returns the correct body' do
            expect(last_response.body).to include_json([
              {
                type: 'command',
                username: 'test_user_3',
                data: {
                  command: 'roll',
                  number_of_dices: 1,
                  number_of_faces: 20,
                  modifier: 2,
                  results: [16]
                }
              }
            ])
          end
        end
      end

      describe 'Secret dice rolls' do
        let!(:roll_dice) {
          message = build(:message, enum_type: :command, player: third_invitation, data: {
            command: 'roll:secret',
            number_of_dices: 1,
            number_of_faces: 20,
            modifier: 2,
            results: [16]
          })
          campaign.messages = [message]
          campaign.save
          message
        }

        describe 'For the sender of the message' do
          before do
            get "/campaigns/#{campaign.id.to_s}/messages", {token: gateway.token, app_key: appli.key, session_id: third_session.token}
          end
          it 'Returns a 200 (OK) status code' do
            expect(last_response.status).to be 200
          end
          it 'Returns the correct body' do
            expect(last_response.body).to include_json([
              {
                type: 'command',
                username: 'test_user_3',
                data: {
                  command: 'roll:secret',
                  number_of_dices: 1,
                  number_of_faces: 20,
                  modifier: 2,
                  results: [16]
                }
              }
            ])
          end
        end
        describe 'For another player' do
          before do
            get "/campaigns/#{campaign.id.to_s}/messages", {token: gateway.token, app_key: appli.key, session_id: session.token}
          end
          it 'Returns a 200 (OK) status code' do
            expect(last_response.status).to be 200
          end
          it 'Returns the correct body' do
            expect(JSON.parse(last_response.body)).to eq []
          end
        end
        describe 'For the game master' do
          before do
            get "/campaigns/#{campaign.id.to_s}/messages", {token: gateway.token, app_key: appli.key, session_id: admin_session.token}
          end
          it 'Returns a 200 (OK) status code' do
            expect(last_response.status).to be 200
          end
          it 'Returns the correct body' do
            expect(last_response.body).to include_json([
              {
                type: 'command',
                username: 'test_user_3',
                data: {
                  command: 'roll:secret',
                  number_of_dices: 1,
                  number_of_faces: 20,
                  modifier: 2,
                  results: [16]
                }
              }
            ])
          end
        end
      end
    end

    it_should_behave_like 'a route', 'post', '/campaign_id/messages'

    describe '400 errors' do
      describe 'session ID not given' do
        before do
          get '/campaigns/campaign_id/messages', {token: gateway.token, app_key: appli.key}
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
        let!(:third_account) { create(:account, email: 'third@test.com', username: 'Third account') }
        let!(:other_session) { create(:session, account: third_account, token: 'truite violette') }

        before do
          get "/campaigns/#{campaign.id.to_s}/messages", {token: gateway.token, app_key: appli.key, session_id: other_session.token}
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