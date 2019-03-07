module Controllers
  class Files < Controllers::Base

    def service
      return Services::Files.instance
    end

    declare_route 'get', '/:id/files/:file_id' do
      _session = check_session('files_get')
      _campaign = get_campaign_for(_session, 'files_get', strict: false)

      if service.campaign_has_file?(_campaign, params['file_id'])
        service.get_campaign_file(_campaign, params['file_id'])
      else
        custom_error 404, 'files_get.file_id.unknown'
      end
    end

    declare_route 'get', '/:id/files' do
      _session = check_session('files_list')
      _campaign = get_campaign_for(_session, 'files_list', strict: false)
      halt 200, service.list(_campaign, _session).to_json
    end

    declare_route 'post', '/:id/files' do
      check_presence 'name', 'content', route: 'files_creation'
      _session = check_session('files_creation')
      _campaign = get_campaign_for(_session, 'files_creation', strict: true)

      file = service.create(_session, _campaign, params['name'], params['content'])

      if file.save
        halt 200, Decorators::File.new(file).to_h.to_json
      else
        model_error file, 'files_creation'
      end
    end

    declare_route 'delete', '/:id/files/:file_id' do
      _session = check_session('files_deletion')
      _campaign = get_campaign_for(_session, 'files_deletion', strict: true)

      if service.campaign_has_file?(_campaign, params['file_id'])
        service.delete_campaign_file(_campaign, params['file_id'])
        halt 200, {message: 'deleted'}.to_json
      else
        custom_error 404, 'files_deletion.file_id.unknown'
      end
    end


    declare_route 'put', '/:id/files/:file_id' do
      _session = check_session('permissions_creation')
      _campaign = get_campaign_for(_session, 'permissions_creation', strict: true)

      file = service.get(params['file_id'])
      if file.nil?
        custom_error 404, 'permissions_creation.file_id.unknown'
      elsif params.has_key?('permissions')
        Services::Files.instance.update_permissions(file, params['permissions'])
      end
      halt 200, {message: 'updated'}.to_json
    end
  end
end