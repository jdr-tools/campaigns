RSpec.shared_examples 'POST /' do
  describe 'POST /' do
    describe 'Nominal case' do
      before do
        post '/campaigns', {
          token: gateway.token,
          app_key: appli.key,
          title: 'some title',
          description: 'test',
          is_private: true,
          max_players: 4,
          creator_id: account.id.to_s,
          tags: ['test_tag']
        }
      end
      it 'returns a Created (201) status when correctly creating a campaign' do
        expect(last_response.status).to be 201
      end
      it 'returns the correct body when correctly creating a campaign' do
        expect(JSON.parse(last_response.body)).to eq({'message' => 'created'})
      end
      describe 'created campaign' do
        let!(:created_campaign) { Arkaan::Campaign.all.first }

        it 'has created a new campaign' do
          expect(Arkaan::Campaign.all.count).to be 1
        end
        it 'has created a campaign with the correct title' do
          expect(created_campaign.title).to eq 'some title'
        end
        it 'has created a campaign with the correct description' do
          expect(created_campaign.description).to eq 'test'
        end
        it 'has created a private campaign' do
          expect(created_campaign.is_private).to be true
        end
        it 'has_created a campaign with the correct creator' do
          expect(created_campaign.creator.id.to_s).to eq account.id.to_s
        end
        it 'has created a campaign with the correct max number of player' do
          expect(created_campaign.max_players).to be 4
        end
        it 'has inserted the correct tags in the campaign' do
          expect(created_campaign.tags).to eq ['test_tag']
        end
      end
      describe 'created tag' do
        let!(:created_tag) { Arkaan::Campaigns::Tag.all.first }

        it 'has created tags for the new campaign' do
          expect(Arkaan::Campaigns::Tag.all.count).to be 1
        end
        it 'has created a tag with the correct content' do
          expect(created_tag.content).to eq 'test_tag'
        end
        it 'has created a tag with the correct count' do
          expect(created_tag.count).to be 1
        end
      end
    end

    describe 'when no tags are given' do
      before do
        post '/campaigns', {token: gateway.token, app_key: appli.key, title: 'some title', is_private: true, creator_id: account.id.to_s}
      end
      it 'has correctly created a campaign' do
        expect(Arkaan::Campaign.all.count).to be 1
      end
      it 'has created no tags in the database' do
        expect(Arkaan::Campaigns::Tag.all.count).to be 0
      end
      it 'has created a campaign with an empty tags array' do
        expect(Arkaan::Campaign.first.tags).to eq []
      end
    end

    describe 'when the privacy flag is given as a string' do
      before do
        post '/campaigns', {token: gateway.token, app_key: appli.key, title: 'some title', is_private: 'true', creator_id: account.id.to_s}
      end
      it 'has correctly created a campaign' do
        expect(Arkaan::Campaign.all.count).to be 1
      end
      it 'has created no tags in the database' do
        expect(Arkaan::Campaigns::Tag.all.count).to be 0
      end
      it 'has created a campaign with a right privacy setting' do
        expect(Arkaan::Campaign.first.is_private).to eq(true)
      end
    end

    describe 'when the privacy flag is given at false' do
      before do
        post '/campaigns', {token: gateway.token, app_key: appli.key, title: 'some title', is_private: false, creator_id: account.id.to_s}
      end
      it 'has correctly created a campaign' do
        expect(Arkaan::Campaign.all.count).to be 1
      end
      it 'has created no tags in the database' do
        expect(Arkaan::Campaigns::Tag.all.count).to be 0
      end
      it 'has created a campaign with a right privacy setting' do
        expect(Arkaan::Campaign.first.is_private).to eq(false)
      end
    end

    describe 'when the privacy flag is given as a string at false' do
      before do
        post '/campaigns', {token: gateway.token, app_key: appli.key, title: 'some title', is_private: 'false', creator_id: account.id.to_s}
      end
      it 'has correctly created a campaign' do
        expect(Arkaan::Campaign.all.count).to be 1
      end
      it 'has created no tags in the database' do
        expect(Arkaan::Campaigns::Tag.all.count).to be 0
      end
      it 'has created a campaign with a right privacy setting' do
        expect(Arkaan::Campaign.first.is_private).to eq(false)
      end
    end

    describe 'when the same tag is given several times' do
      before do
        post '/campaigns', {
          token: gateway.token,
          app_key: appli.key,
          title: 'some title',
          description: 'test',
          is_private: true,
          creator_id: account.id.to_s,
          tags: ['test_tag', 'test_tag']
        }
      end
      it 'has correctly created a campaign' do
        expect(Arkaan::Campaign.all.count).to be 1
      end
      it 'has correctly populated the tags for the campaign' do
        expect(Arkaan::Campaign.first.tags).to eq ['test_tag']
      end
      it 'has created a tag for the campaign' do
        expect(Arkaan::Campaigns::Tag.all.count).to be 1
      end
      it 'has created a tag with the correct count' do
        expect(Arkaan::Campaigns::Tag.first.count).to be 1
      end
    end

    it_should_behave_like 'a route', 'post', '/'

    describe 'bad requests errors' do
      describe 'Campaign title not given error' do
        before do
          post '/campaigns', {token: gateway.token, app_key: appli.key, description: 'test', is_private: true, creator_id: account.id.to_s}
        end
        it 'returns a Bad Request (400) error when not giving the campaign title' do
          expect(last_response.status).to be 400
        end
        it 'returns the correct body when not giving the campaign title' do
          expect(JSON.parse(last_response.body)).to include_json({
            'status' => 400,
            'field' => 'title',
            'error' => 'required'
          })
        end
        it 'has not created a new campaign' do
          expect(Arkaan::Campaign.count).to be 0
        end
      end

      describe 'Campaign title too short' do
        before do
          post '/campaigns', {token: gateway.token, app_key: appli.key, title: 'a', is_private: true, creator_id: account.id.to_s}
        end
        it 'returns an Bad Request (400) error when the title is too short' do
          expect(last_response.status).to be 400
        end
        it 'returns the correct body when the campaign title is too short' do
          expect(JSON.parse(last_response.body)).to include_json({
            'status' => 400,
            'field' => 'title',
            'error' =>'minlength'
          })
        end
        it 'has not created a new campaign' do
          expect(Arkaan::Campaign.count).to be 0
        end
      end

      describe 'campaign title already taken' do
        before do
          _campaign = create(:campaign, creator: account)
          post '/campaigns', {token: gateway.token, app_key: appli.key, title: _campaign.title, creator_id: account.id.to_s}
        end
        it 'returns an Bad Request (400) error when the title is already used' do
          expect(last_response.status).to be 400
        end
        it 'returns the correct body when the campaign title is already used by this user' do
          expect(JSON.parse(last_response.body)).to include_json({
            'status' => 400,
            'field' => 'title',
            'error' => 'uniq'
            })
        end
        it 'has not created a new campaign' do
          expect(Arkaan::Campaign.count).to be 1
        end
      end
    end
  end
end