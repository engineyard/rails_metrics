# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require 'rails_metrics/version'

Gem::Specification.new do |s|
  s.name = "rails_metrics"
  s.version = RailsMetrics::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors = ["Jos\303\251 Valim"]
  s.homepage = %q{http://github.com/engineyard}
  s.summary = "Metrics measurement for your app on top of ActiveSupport::Notifications"
  s.description = "Metrics measurement for your app on top of ActiveSupport::Notifications"
  s.email = "contact@engineyard.com"

  s.rdoc_options = ["--charset=UTF-8"]
  s.extra_rdoc_files = ["README.rdoc"]

  s.require_paths = ["lib"]
  s.files = `git ls-files -- {app,config,lib,public}/*`.split("\n")
  s.test_files = `git ls-files -- test/*`.split("\n")

  s.add_dependency("rails", "~> 3.0.0")
  s.add_development_dependency("rake", "0.8.7")
  s.add_development_dependency("mysql", "~> 2.8")
  s.add_development_dependency("webrat", "~> 0.7.0")
end

