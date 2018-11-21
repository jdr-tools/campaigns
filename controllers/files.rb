module Controllers
  class Files < Controllers::Base

    declare_route 'get', '/:id/files/:file_id' do
      _session = check_session('files_get')
      _campaign = get_campaign_for(_session, 'files_get', strict: false)

      if ::Services::Files.instance.campaign_has_file?(_campaign, params['file_id'])
        ::Services::Files.instance.get_campaign_file(_campaign, params['file_id'])
      else
        custom_error 404, 'files_get.file_id.unknown'
      end
    end

    declare_route 'get', '/:id/files' do
      _session = check_session('files_list')
      _campaign = get_campaign_for(_session, 'files_list', strict: false)
      files = ::Services::Files.instance.list(_campaign)
      halt 200, files.to_json
    end

    declare_route 'post', '/:id/files' do
      check_presence 'name', 'content', route: 'files_creation'
      _session = check_session('files_creation')
      _campaign = get_campaign_for(_session, 'files_creation', strict: true)

      file = ::Services::Files.instance.create(_session, _campaign, params)

      if file.save
        if ::Services::Files.instance.store(file, params)
          halt 200, Decorators::File.new(file).to_h.to_json
        else
          custom_error 400, 'files_creation.upload.failed'
        end
      else
        model_error file, 'files_creation'
      end
    end

    declare_route 'delete', '/:id/files/:file_id' do
      _session = check_session('files_deletion')
      _campaign = get_campaign_for(_session, 'files_deletion', strict: true)

      if ::Services::Files.instance.campaign_has_file?(_campaign, params['file_id'])
        ::Services::Files.instance.delete_campaign_file(_campaign, params['file_id'])
        halt 200, {message: 'deleted'}.to_json
      else
        custom_error 404, 'files_deletion.file_id.unknown'
      end
    end
  end
end