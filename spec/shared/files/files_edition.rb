RSpec.shared_examples 'PUT /:id/files/:file_id' do

  describe 'PUT /:id/files/:file_id' do

    let!(:campaign) { create(:campaign, id: 'campaign_id', title: 'other campaign', creator: account) }
    let!(:player) { create(:account) }
    let!(:invitation) { create(:accepted_invitation, campaign: campaign, account: player) }
    let!(:master_invitation) { campaign.invitations.where(enum_status: :creator).first }
    let!(:perm_file) {
      create(:file, {
        campaign: campaign,
        creator: master_invitation,
        name: 'test_permissions.txt',
        mime_type: 'text/plain'
      })
    }

    # Makes the call to modify the file's permissions with the given permissions.
    # @param permissions [Array] the array of permissions to set on the file.
    # @param custom_url [Boolean, String] leave empty to use the default URL, or pass a custom URL to use it.
    def modify_permissions(permissions = [], custom_url = false)
      _url = custom_url ? custom_url : "/campaigns/#{campaign.id}/files/#{perm_file.id}"
      put _url, {session_id: session.token, token: 'test_token', app_key: 'test_key', permissions: permissions}
    end

    describe 'when adding a permission' do
      describe 'Nominal case' do
        before do
          modify_permissions([{invitation_id: invitation.id, level: 'read'}])
        end
        it 'Returns a OK (200) status code' do
          expect(last_response.status).to be 200
        end
        it 'Returns the correct body' do
          expect(last_response.body).to include_json({message: 'updated'})
        end
        describe 'Permissions attributes' do
          let!(:permissions) { perm_file.permissions.where(invitation_id: invitation.id) }
          it 'Has created the permission' do
            expect(permissions.count).to be 1
          end
          it 'Has created the permission with the correct user' do
            expect(permissions.first.invitation.account.username).to eq player.username
          end
          it 'Has created the permission with the correct level' do
            expect(permissions.first.level).to eq :read
          end
        end
      end

      describe 'Alternative case' do
        context 'when the level is not given' do
          before do
            modify_permissions([{invitation_id: invitation.id}])
          end
          it 'Returns a OK (200) status code' do
            expect(last_response.status).to be 200
          end
          it 'Returns the correct body' do
            expect(last_response.body).to include_json({message: 'updated'})
          end
          describe 'Permissions attributes' do
            let!(:permissions) { perm_file.permissions.where(invitation_id: invitation.id) }
            it 'Has created the permission' do
              expect(permissions.count).to be 1
            end
            it 'Has created the permission with the correct user' do
              expect(permissions.first.invitation.account.username).to eq player.username
            end
            it 'Has created the permission with the correct level' do
              expect(permissions.first.level).to eq :read
            end
          end
        end
      end

      it_behaves_like 'a route', 'post', '/campaign_id/files/file_id/permissions'

      describe '404 errors' do
        describe 'When the campaign does not exist' do
          before do
            modify_permissions([{invitation_id: invitation.id, level: 'read'}], "/campaigns/unknown/files/#{perm_file.id}")
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
            modify_permissions([{invitation_id: invitation.id, level: 'read'}], "/campaigns/#{campaign.id}/files/unknown")
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
    
    describe 'when removing a permission' do
      let!(:permission) { create(:permission, invitation: invitation, file: perm_file) }

      describe 'Nominal case' do
        before do
          modify_permissions
          perm_file.reload
        end
        it 'Returns a OK (200) status code' do
          expect(last_response.status).to be 200
        end
        it 'returns the correct body' do
          expect(last_response.body).to include_json({message: 'updated'})
        end
        it 'Has deleted the permission for the user' do
          expect(perm_file.permissions.where(enum_level: :read).count).to be 0
        end
        it 'Has kept the permission for the creator' do
          expect(perm_file.permissions.where(enum_level: :creator).count).to be 1
        end
      end
    end
  end
end