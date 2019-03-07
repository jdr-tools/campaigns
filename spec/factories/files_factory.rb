FactoryGirl.define do
  factory :empty_file, class: Arkaan::Campaigns::File do
    factory :file do
      mime_type 'image/jpg'
      name 'test_file.jpg'
      size 420
    end
  end
end