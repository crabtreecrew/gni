# Read about factories at http://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :external_list_reconciler do
      data "MyText"
      options "MyString"
      progress_status nil
      progress_message "MyString"
    end
end