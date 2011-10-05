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
require File.expand_path(File.dirname(__FILE__) + "/custom_matchers")

require 'eol_scenarios'
EolScenario.load_paths = [ File.join(RAILS_ROOT, 'scenarios') ]

require 'eol_rackbox'

Spec::Runner.configure do |config|
  include EolScenario::Spec
  include GNI::Spec::Helpers

  config.include GNI::Spec::Matchers
  config.use_blackbox = true

  # If you're not using ActiveRecord you should remove these
  # lines, delete config/database.yml and disable :active_record
  # in your config/boot.rb
  config.use_transactional_fixtures = true
  config.use_instantiated_fixtures  = false
  config.fixture_path = RAILS_ROOT + '/spec/fixtures/'

  # == Fixtures
  #
  # You can declare fixtures for each example_group like this:
  #   describe "...." do
  #     fixtures :table_a, :table_b
  #
  # Alternatively, if you prefer to declare them only once, you can
  # do so right here. Just uncomment the next line and replace the fixture
  # names with your fixtures.
  #
  # config.global_fixtures = :table_a, :table_b
  #
  # If you declare global fixtures, be aware that they will be declared
  # for all of your examples, even those that don't use them.
  #
  # You can also declare which fixtures to use (for example fixtures for test/fixtures):
  #
  # config.fixture_path = RAILS_ROOT + '/spec/fixtures/'
  #
  # == Mock Framework
  #
  # RSpec uses it's own mocking framework by default. If you prefer to
  # use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  #
  # == Notes
  #
  # For more information take a look at Spec::Example::Configuration and Spec::Runner
end
