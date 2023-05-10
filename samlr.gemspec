require './lib/samlr/version'

Gem::Specification.new "samlr", Samlr::VERSION do |s|
  s.summary     = "Ruby tools for SAML"
  s.description = "Helps you implement a SAML SP"
  s.authors     = ["Morten Primdahl"]
  s.email       = "primdahl@me.com"
  s.homepage    = "https://github.com/zendesk/samlr"
  s.files       = `git ls-files lib bin config README.md LICENSE`.split("\n")
  s.license     = "Apache License Version 2.0"

  s.required_ruby_version = ">= 2.7"

  s.add_runtime_dependency("nokogiri", ">= 1.5.5")
  s.add_runtime_dependency("uuidtools", ">= 2.1.3")

  s.add_development_dependency("rake")
  s.add_development_dependency("bundler")
  s.add_development_dependency("minitest")
  s.add_development_dependency("bump")

  s.executables << "samlr"
end
