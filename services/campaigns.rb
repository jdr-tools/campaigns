require 'singleton'

module Services
  # The campaigns service wraps methods such as the creation of a campaign.
  # @author Vincent Courtois <courtois.vincent@outlook.com>
  class Campaigns
    include Singleton

    # Builds a new campaign with the given parameters and tags, updating the tags counters.
    # @param parameters [Hash] the parameters to build the campaign with.
    # @param tags [Array<String>] and array of string tags to identify the content of the campaign.
    def build(parameters, tags)
      creator = Arkaan::Account.where(_id: parameters.delete('creator_id')).first
      campaign = Decorators::Campaign.new(Arkaan::Campaign.new(parameters))
      campaign.creator = creator
      campaign.assign_tags(tags.uniq)
      return campaign
    end

    # Updates a given campaign with the provided parameters and tags.
    # @param campaign [Arkaan::Campaign] the campaign to update
    # @param parameters [Hash] an associated array of fields to update on the campaign.
    # @param tags [Array<String>] an array of tags to put in the campaign. It ERASES the previous list of tags and replaces it.
    # @return [Boolean] TRUE if the campaign has successfully been updated, FALSE otherwise.
    def update(campaign, parameters, tags)
      campaign = Decorators::Campaign.new(campaign)
      parameters.each do |key, value|
        campaign[key] = value
      end
      if !tags.nil?
        campaign.delete_tags
        campaign.assign_tags(tags.uniq)
      end
      return campaign.save
    end

    # Deletes an existing campaign and its invitations.
    # @param campaign [Arkaan::Campaign] the campaign you want to delete.
    # @return [Boolean] TRUE if the deletion has been successfully done, FALSE otherwise.
    def delete(campaign)
      campaign.files.pluck(:_id).each do |file|
        Services::Files.instance.delete_campaign_file(campaign, file_id)
      end
      campaign.invitations.each do |invitation|
        invitation.delete
      end
      return campaign.delete
    end

    # Gets the list of campaigns available for the account of the given session.
    # An account can access two types of campaigns :
    # 1. The campaigns he has an invitation in, where the status is NOT blocked.
    # 2. The public campaigns (is_private: false) he has either :
    #    - NO invitation in
    #    - an invitation that has a status that is NOT blocked
    # @param [Arkaan::Authentication::Session] the session associated with the account you want the list of campaigns.
    # @return [Array<Decorators::Campaign>] the list of campaigns for this account
    def list(session)
      # These are all the invitations for this player linked to campaign he's BLOCKED into
      blocked_invitations = Arkaan::Campaigns::Invitation.where(account: session.account, enum_status: :blocked)
      blocked_campaign_ids = blocked_invitations.pluck(:campaign_id)

      creator_invitations = Arkaan::Campaigns::Invitation.where(account: session.account, enum_status: :creator)
      created_campaigns_ids = creator_invitations.pluck(:campaign_id)

      campaigns = Arkaan::Campaign.where(is_private: false, :_id.nin => (blocked_campaign_ids + created_campaigns_ids))

      decorated = Decorators::Campaign.decorate_collection(campaigns).map { |decorator| decorator.with_invitations(session) }
      return decorated
    end
  end
end