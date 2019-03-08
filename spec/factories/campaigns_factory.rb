FactoryGirl.define do
  factory :empty_campaign, class: Arkaan::Campaign do
    factory :campaign do
      title { Faker::Alphanumeric.unique.alphanumeric(20) }
      description 'A longer description of the campaign'
      is_private true
      tags ['test_tag']
    end
  end
end