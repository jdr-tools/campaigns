RSpec.shared_examples 'GET /:id/files' do

  describe 'GET /:id/files' do

    let!(:master) { create(:account) }
    let!(:player) { create(:account) }
    let!(:master_session) { create(:session, account: master) }
    let!(:player_session) { create(:session, account: player) }
    let!(:campaign) { create(:campaign, creator: master) }
    let!(:player_invitation) { create(:accepted_invitation, account: player, campaign: campaign) }
    let!(:master_invitation) { campaign.invitations.where(enum_status: :creator).first }
    let!(:file) { create(:file, creator: master_invitation, campaign: campaign) }

    let(:url) { "/campaigns/#{campaign.id}/files" }

    it_behaves_like 'a route', 'get', '/campaign_id/files'

    describe 'Nominal case' do
      context 'The player has access to the file' do
        let!(:permission) { create(:permission, invitation: player_invitation, file: file) }

        before do
          get url, {session_id: player_session.token, app_key: appli.key, token: gateway.token}
        end

        it 'Returns a OK (200) status code' do
          expect(last_response.status).to be 200
        end
        it 'Returns the correct number of files' do
          expect(JSON.parse(last_response.body).count).to be 1
        end
        it 'Returns the correct body' do
          expect(last_response.body).to include_json([{
            id: file.id.to_s,
            name: file.name,
            type: file.mime_type,
            size: file.size,
            account: {id: master.id.to_s, username: master.username}
          }])
        end
      end

      context 'The player does not have access to the file' do
        before do
          get url, {session_id: player_session.token, app_key: appli.key, token: gateway.token}
        end

        it 'Returns a OK (200) status code' do
          expect(last_response.status).to be 200
        end
        it 'Returns the correct number of files' do
          expect(JSON.parse(last_response.body).count).to be 0
        end
      end
    end

    describe '403 errors' do
      describe 'account not authorized' do
        before do
          get url, {session_id: session.token, app_key: appli.key, token: gateway.token,}
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
  end
end