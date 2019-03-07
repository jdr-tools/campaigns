ruby '2.3.4'
source 'https://rubygems.org'

group :development, :production, :test do
  gem 'sinatra', '2.0.1', require: 'sinatra/base'
  gem 'mongoid', '7.0.1'
  gem 'arkaan' , '1.4.0', path: '../arkaan'
  gem 'draper' , '3.0.1'
  gem 'aws-sdk', '3.0.1'
end

group :developement, :production do
  gem 'rake'
end

group :development, :test do
  gem 'faker'                  , '1.9.3'
  gem 'pry'                    , '0.11.1'
  gem 'rack-test'              , '0.7.0' , require: 'rack/test'
  gem 'rspec'                  , '3.6.0'
  gem 'rspec-json_expectations', '2.1.0'
  gem 'factory_girl'           , '4.8.1'
  gem 'simplecov'              , '0.15.1'
  gem 'database_cleaner'       , '1.6.1'
  gem 'bcrypt'                 , '3.1.11'
  gem 'rubocop'
end