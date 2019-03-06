RSpec.shared_examples 'PUT /:id/files/:file_id' do

  context 'when adding a permission' do

    let!(:other_campaign) { create(:campaign, id: 'other_campaign_id', title: 'other campaign', creator: account) }
    let!(:base_64_content) {'data:text/plain;base64,dGVzdApzYXV0IGRlIGxpZ25lIGV0IGVzcGFjZXM='}
    let!(:player) { create(:account, username: 'player account', email: 'player@account.fr') }
    let!(:invitation) { create(:accepted_invitation, campaign: other_campaign, account: player) }

    before :each do
      post "/campaigns/#{other_campaign.id.to_s}/files", {
        session_id: session.token,
        app_key: 'test_key',
        token: 'test_token',
        name: 'test_permissions.txt',
        content: base_64_content
      }
    end

    let!(:perm_file) {
      _invitation = other_campaign.invitations.where(enum_status: :creator).first
      create(:file, campaign: other_campaign, creator: _invitation, name: 'test_permissions.txt', mime_type: 'text/plain')
    }

    def modify_permissions(permissions, custom_url = false)
      _url = custom_url ? custom_url : "/campaigns/#{other_campaign.id.to_s}/files/#{perm_file.id.to_s}"
      put _url, {session_id: session.token, token: 'test_token', app_key: 'test_key', permissions: permissions}
    end

    describe 'Nominal case' do
      before do
        modify_permissions([{invitation_id: invitation.id.to_s, level: 'read'}])
      end
      it 'Returns a Created (201) status code' do
        expect(last_response.status).to be 201
      end
      it 'Returns the correct body' do
        expect(last_response.body).to include_json({message: 'created'})
      end
      it 'Has created the permission' do
        expect(perm_file.permissions.where(enum_level: :read).count).to be 1
      end
      it 'Has created the permission with the correct user' do
        expect(perm_file.permissions.last.invitation.account.username).to eq 'player account'
      end
      it 'Has created the permission with the correct level' do
        expect(perm_file.permissions.last.level).to eq :read
      end
    end

    describe 'Alternative case' do
      context 'when the level is not given' do
        before do
          modify_permissions([{invitation_id: invitation.id.to_s}])
        end
        it 'Returns a Created (201) status code' do
          expect(last_response.status).to be 201
        end
        it 'Returns the correct body' do
          expect(last_response.body).to include_json({message: 'created'})
        end
        it 'Has created the permission' do
          expect(perm_file.permissions.where(enum_level: :read).count).to be 1
        end
        it 'Has created the permission with the correct user' do
          expect(perm_file.permissions.last.invitation.account.username).to eq 'player account'
        end
        it 'Has created the permission with the correct level' do
          expect(perm_file.permissions.last.level).to eq :read
        end
      end
    end

    it_behaves_like 'a route', 'post', '/campaign_id/files/file_id/permissions'

    describe '400 errors' do
      describe 'When the invitation ID is not given' do
        before do
          modify_permissions([{level: 'read'}])
        end
        it 'Returns a Bad Request (400) status code' do
          expect(last_response.status).to be 400
        end
        it 'Returns the correct body' do
          expect(last_response.body).to include_json({
            status: 400,
            field: 'invitation_id',
            error: 'required'
          })
        end
      end
    end

    describe '404 errors' do
      describe 'When the campaign does not exist' do
        before do
          modify_permissions([{invitation_id: invitation.id.to_s, level: 'read'}], "/campaigns/unknown/files/#{perm_file.id.to_s}")
        end
        it 'Returns a Not Found (404) status code' do
          expect(last_response.status).to be 404
        end
        it 'Returns the correct body' do
          expect(last_response.body).to include_json({
            status: 404,
            field: 'campaign_id',
            error: 'unknown'
          })
        end
      end
      describe 'When the file does not exist' do
        before do
          modify_permissions([{invitation_id: invitation.id.to_s, level: 'read'}], "/campaigns/#{other_campaign.id.to_s}/files/unknown")
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
      describe 'When the invitation does not exist' do
        before do
          modify_permissions([{invitation_id: 'unknown', level: 'read'}])
        end
        it 'Returns a Not Found (404) status code' do
          expect(last_response.status).to be 404
        end
        it 'Returns the correct body' do
          expect(last_response.body).to include_json({
            status: 404,
            field: 'invitation_id',
            error: 'unknown'
          })
        end
      end
    end
  end
end