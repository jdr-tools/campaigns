ENV['RACK_ENV'] = 'test'

if !ENV.has_key?('AWS_ACCESS_KEY_ID') || !ENV.has_key?('AWS_SECRET_ACCESS_KEY')
  puts "Il semblerait que les variables d'environnements Amazon n'aient pas été chargé, tente un 'source .env' pour voir ?"
  exit
end

require 'bundler'
Bundler.require :test

require './controllers/base.rb'
require 'arkaan/specs'

service = Arkaan::Utils::MicroService.instance
  .register_as('campaigns')
  .from_location(__FILE__)
  .in_test_mode

Arkaan::Specs.include_shared_examples