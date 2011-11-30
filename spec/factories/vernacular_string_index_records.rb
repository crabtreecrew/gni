# Read about factories at http://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :vernacular_string_index_record do
      vernacular_string_index nil
      language "MyString"
      locality "MyString"
    end
end