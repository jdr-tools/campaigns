RSpec.shared_examples 'POST /:id/files' do
  describe 'POST /:id/files' do

    before :each do
      Services::Bucket.instance.create_bucket_if_not_exists
    end

    let(:url) { "/campaigns/#{campaign.id.to_s}/files" }

    let!(:campaign) { create(:campaign, creator: account) }
    let!(:content) {'data:text/plain;base64,dGVzdApzYXV0IGRlIGxpZ25lIGV0IGVzcGFjZXM='}
    let!(:invalid_content) {'data:text/rtf;base64,dGVzdApzYXV0IGRlIGxpZ25lIGV0IGVzcGFjZXMK'}
    
    describe 'Nominal case' do
      before do
        post url, {
          session_id: session.token,
          app_key: appli.key,
          token: gateway.token,
          name: 'test.txt',
          content: content
        }
      end
      it 'Returns a OK (200) status code' do
        expect(last_response.status).to be 200
      end
      it 'returns the correct body' do
        expect(last_response.body).to include_json({
          name: 'test.txt',
          type: 'text/plain'
        })
      end
      it 'has created a file in the campaign' do
        campaign.reload
        expect(campaign.files.count).to be 1
      end
      describe 'file parameters' do
        it 'has created a file with the correct name' do
          expect(campaign.files.first.name).to eq 'test.txt'
        end
        it 'has created a file with the correct MIME type' do
          expect(campaign.files.first.mime_type).to eq 'text/plain'
        end
      end

      describe 'AWS created file' do
        let!(:file_id) { JSON.parse(last_response.body)['id'] }
        let(:file_content) { Services::Files.instance.get_campaign_file(campaign, file_id) }

        it 'has the correct content' do
          expect(file_content).to eq content
        end
      end
    end

    it_behaves_like 'a route', 'post', '/campaign_id/files'

    describe :errors do

      before :all do
        Services::Bucket.instance.remove_all
      end

      describe '400 errors' do
        describe 'file content not given' do
          before do
            post url,{
              session_id: session.token,
              app_key: appli.key,
              token: gateway.token,
              name: 'test.txt'
            }
          end
          it 'Returns a Bad request (400) status code' do
            expect(last_response.status).to be 400
          end
          it 'Returns the correct body' do
            expect(last_response.body).to include_json({
              status: 400,
              field: 'content',
              error: 'required'
            })
          end
          it 'has not created the corresponding file' do
            expect(Services::Bucket.instance.file_exists?(campaign, 'test.txt'))
          end
        end
        describe 'filename not given' do
          before do
            post url, {
              session_id: session.token,
              app_key: appli.key,
              token: gateway.token,
              size: 30,
              content: content
            }
          end
          it 'Returns a Bad request (400) status code' do
            expect(last_response.status).to be 400
          end
          it 'Returns the correct body' do
            expect(last_response.body).to include_json({
              status: 400,
              field: 'name',
              error: 'required'
            })
          end
          it 'has not created the corresponding file' do
            expect(Services::Bucket.instance.file_exists?(campaign, 'test.txt'))
          end
        end
        describe 'invalid MIME type' do
          before do
            post url, {
              session_id: session.token,
              app_key: appli.key,
              token: gateway.token,
              size: 30,
              name: 'test.txt',
              content: invalid_content
            }
          end
          it 'Returns a Bad request (400) status code' do
            expect(last_response.status).to be 400
          end
          it 'Returns the correct body' do
            expect(last_response.body).to include_json({
              status: 400,
              field: 'mime_type',
              error: 'pattern'
            })
          end
          it 'has not created the corresponding file' do
            expect(Services::Bucket.instance.file_exists?(campaign, 'test.txt'))
          end
        end
      end

      describe '403 errors' do
        describe 'user not creator' do
          let!(:other_account) { create(:account) }
          let!(:invitation) { create(:accepted_invitation, campaign: campaign, account: other_account) }
          let!(:other_session) { create(:session, account: other_account) }

          before do
            post url, {
              session_id: other_session.token,
              app_key: appli.key,
              token: gateway.token,
              name: 'test.txt',
              content: content
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
          it 'has not created the corresponding file' do
            expect(Services::Bucket.instance.file_exists?(campaign, 'test.txt'))
          end
        end
      end
    end
  end
end