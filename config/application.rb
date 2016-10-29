require File.expand_path('../boot', __FILE__)

# Pick the frameworks you want:
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "active_resource/railtie"
require "sprockets/railtie"
require "taxamatch_rb"
require "biodiversity"
# require "rails/test_unit/railtie"

if defined?(Bundler)
  # If you precompile assets before deploying to production, use this line
  Bundler.require(*Rails.groups(:assets => %w(development test)))
  # If you want your assets lazily compiled in production, use this line
  # Bundler.require(:default, :assets, Rails.env)
end
module Gni
  class Application < Rails::Application
    config.autoload_paths += %W(#{config.root}/lib)
    config.autoload_paths += Dir["#{config.root}/lib/**/"]
    config.active_record.schema_format = :sql
    config.i18n.load_path += Dir[Rails.root.join('my',
                                                 'locales',
                                                 '*.{rb,yml}').to_s]
    config.i18n.default_locale = :en
    config.i18n.enforce_available_locales = false

    config.encoding = "utf-8"
    config.filter_parameters += [:password]
    config.assets.enabled = true
    config.assets.version = '1.0'

    config.generators do |g|
      g.test_framework :rspec, :views => false, :fixture => true
      g.fixture_replacement :factory_girl, :dir => 'spec/factories'
      g.template_engine :haml
    end


  end

  Mysql2::Client.default_query_options[:connect_flags] |=
    Mysql2::Client::LOCAL_FILES

  require Rails.root.join('vendor', 'lib', 'ruby-uuid', 'uuid').to_s
  require Rails.root.join('lib', 'gni').to_s

  Config = OpenStruct.new(
    uuid_namespace: ::UUID.create_v5("globalnames.org", UUID::NameSpace_DNS),
    batch_size: 10_000,
    temp_dir: "/tmp",
    solr_url: ENV["SOLR_URL"] || "http://localhost:8983/solr",
    base_url: ENV["BASE_URL"] || "http://localhost:3000",
    reference_data_source_id: "1",
    curated_data_sources: [],
  )

end
