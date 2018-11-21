RSpec.shared_examples 'GET /:id/files/:file_id' do
  describe 'GET /:id/files/:file_id' do

    before :each do
      post "/campaigns/#{campaign.id.to_s}/files", {
        session_id: session.token,
        app_key: 'test_key',
        token: 'test_token',
        name: 'test.txt',
        content: base_64_content
      }
    end

    describe 'When the file exists' do
      let!(:base_64_content) {'data:text/plain;base64,dGVzdApzYXV0IGRlIGxpZ25lIGV0IGVzcGFjZXMK'}
      let!(:file_id) {
        campaign.reload
        campaign.invitations.first.files.first.id.to_s
      }

      after :each do
        delete "/campaigns/#{campaign.id.to_s}/files/#{file_id}", {
          session_id: session.token,
          app_key: 'test_key',
          token: 'test_token'
        }
      end

      describe 'Nominal case' do
        before do
          get "/campaigns/#{campaign.id.to_s}/files/#{file_id}", {
            session_id: session.token,
            app_key: 'test_key',
            token: 'test_token'
          }
        end
        it 'Returns a OK (200) status code' do
          expect(last_response.status).to be 200
        end
        it 'Returns the correct body' do
          expect(last_response.body).to eq base_64_content
        end
      end

      it_behaves_like 'a route', 'get', '/campaigns/campaign_id/files/file_id'

      describe 'Errors' do
        describe '403 errors' do
          let!(:other_account) { create(:account, username: 'Babaussine', email: 'test@other.com') }
          let!(:other_session) { create(:session, token: 'any_other_token', account: other_account) }

          describe 'when the user is not in the campaign' do
            before do
              get "/campaigns/#{campaign.id.to_s}/files/#{file_id}", {
                session_id: other_session.token,
                app_key: 'test_key',
                token: 'test_token'
              }
            end
            it 'Returns a Forbidden (403) status code' do
              expect(last_response.status).to be 403
            end
            it 'Returns the correct body' do
              expect(last_response.body).to include_json({
                status: 403,
                field: 'session_id',
                error: 'forbidden'
              })
            end
          end
        end
        describe '404 errors' do
          describe 'When the file is not found' do
            before do
              get "/campaigns/#{campaign.id.to_s}/files/unknown_file_id", {
                session_id: session.token,
                app_key: 'test_key',
                token: 'test_token'
              }
            end
            it 'Returns a Not Found (404) status code' do
              expect(last_response.status).to be 404
            end
            it 'Returns the correct body' do
              expect(last_response.body).to include_json({
                status: 404,
                field: 'file_id',
                error: 'unknown'
              })
            end
          end
        end
      end
    end
  end
end