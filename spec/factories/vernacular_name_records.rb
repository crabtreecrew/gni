# Read about factories at http://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :vernacular_name_record do
      name_string_index_record nil
      vernacular_name_string nil
      language "MyString"
      locality "MyString"
    end
end