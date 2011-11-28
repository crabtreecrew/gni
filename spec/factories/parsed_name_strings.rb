# Read about factories at http://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :parsed_name_string do
      parser_version "MyString"
      parsed false
      parser_type 1
      data "MyText"
    end
end