ENV['RACK_ENV'] = 'test'

require 'bundler'
Bundler.require :test

require './controllers/base.rb'
require 'arkaan/specs'

service = Arkaan::Utils::MicroService.instance
  .register_as('campaigns')
  .from_location(__FILE__)
  .in_test_mode

Arkaan::Specs.include_shared_examples