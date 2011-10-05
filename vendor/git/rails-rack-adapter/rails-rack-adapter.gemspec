# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{rails-rack-adapter}
  s.version = "1.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["remi"]
  s.date = %q{2009-03-13}
  s.description = %q{Thin's Rack::Adapter::Rails extracted to its own gem}
  s.email = %q{remi@remitaylor.com}
  s.files = ["Rakefile", "VERSION.yml", "COPYING", "README.rdoc", "lib/rack", "lib/rack/adapter", "lib/rack/adapter/rails.rb", "lib/rails-rack-adapter.rb"]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/remi/rails-rack-adapter}
  s.rdoc_options = ["--inline-source", "--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{Thin's Rack::Adapter::Rails extracted to its own gem}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
