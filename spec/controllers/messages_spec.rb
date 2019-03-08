RSpec.describe Controllers::Messages do

  before :each do
    DatabaseCleaner.clean
  end

  let!(:account) { create(:account) }
  let!(:gateway) { create(:gateway) }
  let!(:appli) { create(:application, creator: account) }

  def app
    Controllers::Messages.new
  end

  # rspec spec/controllers/messages_spec.rb[1:1]
  include_examples 'GET /:id/messages'

  # rspec spec/controllers/messages_spec.rb[1:2]
  include_examples 'POST /:id/messages'

  # rspec spec/controllers/messages_spec.rb[1:3]
  include_examples 'POST /:id/commands'

  # rspec spec/controllers/messages_spec.rb[1:4]
  include_examples 'DELETE /:id/messages/:message_id'
end