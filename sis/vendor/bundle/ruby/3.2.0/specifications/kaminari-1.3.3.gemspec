# -*- encoding: utf-8 -*-
# stub: kaminari 1.3.3 ruby lib

Gem::Specification.new do |s|
  s.name = "kaminari".freeze
  s.version = "1.3.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "changelog_uri" => "https://github.com/kaminari/kaminari/blob/master/CHANGELOG.md", "rubygems_mfa_required" => "true", "source_code_uri" => "https://github.com/kaminari/kaminari/" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Akira Matsuda".freeze, "Yuki Nishijima".freeze, "Zachary Scott".freeze, "Hiroshi Shibata".freeze]
  s.date = "1980-01-02"
  s.description = "Kaminari is a Scope & Engine based, clean, powerful, agnostic, customizable and sophisticated paginator for Rails 4+".freeze
  s.email = ["ronnie@dio.jp".freeze]
  s.homepage = "https://github.com/kaminari/kaminari".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.0.0".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "A pagination engine plugin for Rails 4+ and other modern frameworks".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<activesupport>.freeze, [">= 4.1.0"])
  s.add_runtime_dependency(%q<kaminari-core>.freeze, ["= 1.3.3"])
  s.add_runtime_dependency(%q<kaminari-actionview>.freeze, ["= 1.3.3"])
  s.add_runtime_dependency(%q<kaminari-activerecord>.freeze, ["= 1.3.3"])
  s.add_development_dependency(%q<test-unit-rails>.freeze, [">= 0"])
  s.add_development_dependency(%q<bundler>.freeze, [">= 1.0.0"])
  s.add_development_dependency(%q<rr>.freeze, [">= 0"])
  s.add_development_dependency(%q<capybara>.freeze, [">= 1.0"])
end
