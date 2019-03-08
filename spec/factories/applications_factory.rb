FactoryGirl.define do
  factory :empty_application, class: Arkaan::OAuth::Application do
    factory :application do
      name Faker::App.unique.name
      key { Faker::Alphanumeric.unique.alphanumeric(20) }
      premium true
    end
  end
end