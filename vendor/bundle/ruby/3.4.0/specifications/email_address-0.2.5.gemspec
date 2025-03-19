# -*- encoding: utf-8 -*-
# stub: email_address 0.2.5 ruby lib

Gem::Specification.new do |s|
  s.name = "email_address".freeze
  s.version = "0.2.5".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Allen Fair".freeze]
  s.date = "2025-01-09"
  s.description = "The EmailAddress Gem to work with and validate email addresses.".freeze
  s.email = ["allen.fair@gmail.com".freeze]
  s.homepage = "https://github.com/afair/email_address".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new([">= 2.5".freeze, "< 4".freeze])
  s.rubygems_version = "3.6.2".freeze
  s.summary = "This gem provides a ruby language library for working with and validating email addresses. By default, it validates against conventional usage, the format preferred for user email addresses. It can be configured to validate against RFC \u201CStandard\u201D formats, common email service provider formats, and perform DNS validation.".freeze

  s.installed_by_version = "3.6.2".freeze

  s.specification_version = 4

  s.add_development_dependency(%q<rake>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<minitest>.freeze, ["~> 5.11".freeze])
  s.add_development_dependency(%q<bundler>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<activerecord>.freeze, ["~> 8.0.0".freeze])
  s.add_development_dependency(%q<sqlite3>.freeze, ["~> 2.1".freeze])
  s.add_development_dependency(%q<standard>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<net-smtp>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<simplecov>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<pry>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<bigdecimal>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<mutex_m>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<irb>.freeze, [">= 0".freeze])
  s.add_runtime_dependency(%q<base64>.freeze, [">= 0".freeze])
  s.add_runtime_dependency(%q<simpleidn>.freeze, [">= 0".freeze])
end
