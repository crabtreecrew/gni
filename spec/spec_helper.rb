# This file is copied to ~/spec when you run 'ruby script/generate rspec'
# from the project root directory.
ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'spec/autorun'
#require 'spec'
require 'spec/rails'

#hack added to make has_tag method compatible with rails 2.3.4
require 'action_controller'
require 'action_controller/assertions/selector_assertions'
include ActionController::Assertions::SelectorAssertions
#end hack


require File.expand_path(File.dirname(__FILE__) + "/factories")
require File.expand_path(File.dirname(__FILE__) + "/gni_spec_helpers")

require 'eol_scenarios'
EolScenario.load_paths = [ File.join(RAILS_ROOT, 'scenarios') ]

#require 'eol_rackbox'
require 'capybara/rails'
require 'capybara/dsl'

Spec::Runner.configure do |config|
  include EolScenario::Spec
  include GNI::Spec::Helpers

  config.include(Capybara, :type => :integration)
  config.use_transactional_fixtures = true
  config.use_instantiated_fixtures  = false
  config.fixture_path = RAILS_ROOT + '/spec/fixtures/'
end
