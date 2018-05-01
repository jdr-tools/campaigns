module Controllers
  class Campaigns < Arkaan::Utils::Controller

    load_errors_from __FILE__

    declare_route 'get', '/' do
      session = check_session('list')
      campaigns = Arkaan::Campaign.where(is_private: false).not.where(creator: session.account)
      decorated = Decorators::Campaign.decorate_collection(campaigns)
      halt 200, {count: campaigns.count, items: decorated.map(&:to_h)}.to_json
    end

    declare_route 'get', '/creations' do
      session = check_session('own_list')
      campaigns = Arkaan::Campaign.where(creator: session.account)
      decorated = Decorators::Campaign.decorate_collection(campaigns)
      halt 200, {count: campaigns.count, items: decorated.map(&:to_h)}.to_json
    end

    declare_route 'get', '/:id' do
      campaign = check_session_and_campaign(action: 'informations', strict: false)
      halt 200, Decorators::Campaign.new(campaign).to_h.to_json
    end

    declare_route 'get', '/:id/invitations' do
      campaign = check_session_and_campaign(action: 'invitations', strict: false)
      halt 200, Decorators::Campaign.new(campaign).invitations.to_json
    end

    declare_route 'post', '/' do
      check_presence('title', 'creator_id', route: 'creation')
      campaign = Services::Campaigns.instance.build(campaign_params, tags || [])
      if campaign.valid?
        campaign.save
        halt 201, {message: 'created'}.to_json
      else
        model_error(campaign, 'creation')
      end
    end

    declare_route 'put', '/:id' do
      campaign = check_session_and_campaign(action: 'update')
      if Services::Campaigns.instance.update(campaign, campaign_params, tags)
        halt 200, {message: 'updated'}.to_json
      else
        model_error(campaign, 'update')
      end
    end

    declare_route 'delete', '/:id' do
      campaign = check_session_and_campaign(action: 'deletion')
      campaign.delete
      halt 200, {message: 'deleted'}.to_json
    end

    # Returns the parameters allowed to create or update a campaign.
    # @return [Hash] the parameters allowed in the dition or creation of a campaign.
    def campaign_params
      params.select do |key, value|
        ['title', 'description', 'is_private', 'creator_id'].include?(key)
      end
    end

    # Checks several parameters about the session and the campaign :
    # - the session ID must be given
    # - the session must be found in the database
    # - the campaign must be found in the database
    # - the user must be authorized to act on the campaign.
    # To be authorized to to act on a campaign, the user :
    # - must have created it in strict mode
    # - must have created it or be invited in it, or the campaign bu public in not strict mode.
    #
    # @param action [String] the path to the errors in the errors configuration file.
    # @param strict [Boolean] TRUE to use strict mode, FALSE otherwise.
    #
    # @return [Arkaan::Campaign] the campaign found, where the user is authorized.
    def check_session_and_campaign(action:, strict: true)
      session = check_session(action)
      campaign = get_campaign_for(session, action, strict: strict)
      return campaign
    end

    # Checks if the session ID is given, and the session currently existing.
    # @param action [String] the category in the configuration file to find the errors for the session.
    # @return [Arkaan::Authentication::Session] the session found for the given session_id.
    def check_session(action)
      check_presence('session_id', route: action)
      session = Arkaan::Authentication::Session.where(token: params['session_id']).first
      custom_error(404, "#{action}.session_id.unknown") if session.nil?
      return session
    end

    # Gets the campaign for the given session, checking its privilege to access it.
    # See the :check_session_and_campaign above for details about permissions.
    #
    # @param session [Arkaan::Authentication::Session] the session to check the privilege of.
    # @param action [String] the category in the configuration file to find the errors for the session.
    # @param strict [Boolean] TRUE to use strict mode, FALSE otherwise.
    #
    # @return [Arkaan::Campaign] the campaign found, where the user is authorized.
    def get_campaign_for(session, action, strict: false)
      campaign = Arkaan::Campaign.where(id: params['id']).first
      custom_error(404, "#{action}.campaign_id.unknown") if campaign.nil?
      custom_error(403, "#{action}.session_id.forbidden") if !Services::Permissions.instance.authorized?(campaign, session, strict: strict)
      return campaign
    end

    def tags
      return params['tags'].nil? ? nil : params['tags'].select { |tag| tag != '' }
    end
  end
end