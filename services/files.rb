module Services
   # This service handles the deposit of files in amazon AWS and the creation of the files objects in campaigns.
   # @author Vincent Courtois <courtois.vincent@outlook.com>
  class Files
    include Singleton

    # @!attribute [r] bucket
    #   @return [Services::Bucket] the service to make direct actions on the campaigns bucket.
    attr_reader :bucket

    def initialize
      @bucket = ::Services::Bucket.instance
    end

    # Creates the file and stores it in the AWS bucket but does NOT persist it in the database
    # @param session [Arkaan::Authentication::Session] the session of the account creating the file.
    # @param campaign [Arkaan::campaign] the campaign the file will be created in.
    # @param name [String] the name of the file to store.
    # @param content [String] the base64 content of the file to store.
    # @return [Arkaan::campaigns::File] the created file in the database, not yet persisted (but the upload has succeeded).
    def create(session, campaign, name, content)
      invitation = campaign.invitations.where(account: session.account).first
      file = Arkaan::Campaigns::File.new({
        name: name,
        mime_type: parse_mime_type(content),
        campaign: campaign,
        creator: invitation
      })
      return file if !file.valid?
      if !store(file, content)
        raise Arkaan::Utils::Errors.new(action: 'files_creation', field: 'upload', error: 'failed')
      end
      return file
    end

    # Stores a file, already persisted in the database, on amazon S3.
    # @param file [Arkaan::Campaigns::File] the file with the informations to store on AWS.
    # @param content [String] the text representation of the content of the file.
    def store(file, content)
      bucket.store(file.campaign, file.name, content)
      size = bucket.file_size(file.campaign, file.name)
      file.update_attribute(:size, size)
    end

    # List the files for a campaign by aggregating the files of the different invitations.
    # @param campaign [Arkaan::Campaign] the campaign to obtain the files from.
    # @return [Array<Hash>] a list of decorated files represented as hashes.
    def list(campaign, session)
      invitation = campaign.invitations.where(account_id: session.account.id).first
      files = campaign.files.to_a.select do |file|
        !file.permissions.where(invitation_id: invitation.id).first.nil?
      end
      return Decorators::File.decorate_collection(files).map(&:to_h)
    end

    # Returns the text representation of the file identified by this ID.
    # @param campaign [Arkaan::Campaign] the campaign the file is in.
    # @param file_id [String] the unique identifier of the file.
    # @return [String, NilClass] the string representation of the file, or nil if the file does not exist in the database.
    def get_campaign_file(campaign, file_id)
      file = campaign.files.where(id: file_id).first
      if !file.nil?
        raw_content = bucket.file_content(campaign, file.name)
        return "data:#{file.mime_type};base64,#{Base64.encode64(raw_content)}".strip
      end
    end

    # Checks if the campaign has a file with the given unique identifier.
    # @param campaign [Arkaan::Campaign] the campaign the files is supposed to be in.
    # @param file_id [String] the unique identifier of the string to check the existence.
    def campaign_has_file?(campaign, file_id)
      return !campaign.files.where(id: file_id).first.nil?
    end

    # Searches for a file in the given campaign with the given identifier, then deletes it, and deletes it from AWS.
    # @param campaign [Arkaan::Campaign] the campaign the file you want to delete is in.
    # @param file_id [String] the unique identifier for the file.
    def delete_campaign_file(campaign, file_id)
      file = campaign.files.where(id: file_id).first
      if !file.nil?
        file.delete
        bucket.delete_file(campaign, file.name)
      end
    end

    # Parses the MIME type from the file content given with a format : data:<mime_type>;base64,<content>
    # @param content [String] the string representation of the content of the file.
    # @return [String] the MIME type of the file (eq: "plain/text").
    def parse_mime_type(content)
      return content.split(';', 2).first.split(':', 2).last
    end

    # Updates the permissions on a file, this is done in two steps :
    # 1. Remove the permissions that are not given in the update permissions parameters
    # 2. Add the permissions that does not already exist in the file but are given in the hash.
    #
    # @param file [Arkaan::Campaigns::File] the file to update the permissions of.
    # @param permissions [Array<Hash>] an array of permissions, each permission is a hash responding to the :invitation and :level methods.
    def update_permissions(file, permissions)
      _permissions = parse_permissions(permissions)
      file.permissions.where(:enum_level.ne => :creator).each do |tmp_perm|
        still_existing = _permissions.select { |p| p.invitation.id == tmp_perm.invitation.id }
        tmp_perm.delete if still_existing.count == 0
      end
      _permissions.each do |tmp_perm|
        existing = file.permissions.where(invitation_id: tmp_perm[:invitation].id).first
        if existing.nil?
          Arkaan::Campaigns::Files::Permission.create(file: file, invitation: tmp_perm[:invitation], enum_level: tmp_perm[:level])
        else
          existing.update_attribute(:level, tmp_perm[:level])
        end
      end
    end

    # Parses the permissions, only returning the valid ones, aand transforming the invitations IDs in invitations.
    # @param permissions [Array<Hash>] the raw permissions to filter and transform.
    # @return [Array<Hash>] an array of hashes responding to the :invitation and :level methods.
    def parse_permissions(permissions)
      parsed_permissions = []
      permissions.each do |permission|
        if permission.is_a?(Hash) && permission.has_key?('invitation_id')
          invitation = Arkaan::Campaigns::Invitation.where(id: permission['invitation_id']).first
          raise Services::Exceptions::UnknownInvitationId.new if invitation.nil?
          level = permission['level'].to_sym rescue :read
          parsed_permissions << {invitation: invitation, level: level}
        end
      end
      return parsed_permissions
    end

    def get(file_id)
      return Arkaan::Campaigns::File.where(id: file_id).first
    end
  end
end