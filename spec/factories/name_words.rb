# Read about factories at http://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :name_word do
      word "MyString"
      first_letter "MyString"
      length 1
    end
end