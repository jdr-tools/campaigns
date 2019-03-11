module Decorators
  class Campaign < Draper::Decorator
    delegate_all

    # Assign an array of tags to a campaign and refreshes or creates the associated counters.
    # @param tags [Array<String>] the tags to assign to the campaign in the current decorator.
    def assign_tags(tags)
      tags.each do |tag|
        tag_object = Arkaan::Campaigns::Tag.where(content: tag).first
        if tag_object.nil?
          Arkaan::Campaigns::Tag.create(content: tag, count: 1)
        else
          tag_object.count = tag_object.count + 1
          tag_object.save
        end
      end
      object.tags = tags
    end

    # Deletes all the tags for the campaign, and updates the associated tags counters.
    def delete_tags
      object.tags.each do |tag|
        tag_object = Arkaan::Campaigns::Tag.where(content: tag).first
        if tag_object.count > 1
          tag_object.count = tag_object.tag - 1
          tag_object.save
        else
          tag_object.delete
        end
      end
    end

    def invitations
      Decorators::Invitation.decorate_collection(object.invitations.order_by(enum_status: :asc)).map(&:to_h)
    end

    def players_count
      return object.invitations.where(enum_status: :accepted).count
    end

    def waiting_count
      return object.invitations.where(:enum_status.in => [:pending, :request]).count
    end

    def to_creator_h
      return to_h.merge({waiting_players: waiting_count})
    end

    def to_h
      return {
        id: object._id.to_s,
        title: object.title,
        description: object.description,
        is_private: object.is_private,
        max_players: object.max_players,
        current_players: players_count,
        creator: {
          id: object.creator.id.to_s,
          username: object.creator.username
        },
        tags: object.tags
      }
    end

    def with_invitations(session)
      invitation = object.invitations.where(account: session.account).first
      display_inv = invitation.nil? || invitation.status_left? || invitation.status_expelled? || invitation.status_refused?
      return to_h.merge({
        invitation: display_inv ? nil : {
          id: invitation.id.to_s,
          created_at: invitation.created_at.utc.iso8601,
          status: invitation.enum_status.to_s
        }
      })
    end
  end
end