require File.expand_path("../lib/dagoba/version", __FILE__)

Gem::Specification.new do |s|
  s.name = "dagoba"
  s.version = Dagoba::VERSION

  s.required_ruby_version = ">= 2.7.0"

  s.authors = ["Zach Thomae"]
  s.email = ["zach@thomae.co"]
  s.summary = "A simple graph database"
  s.description = s.summary
  s.homepage = "https://github.com/zthomae/dagoba-rb"
  s.licenses = ["MIT"]

  s.require_paths = ["lib"]
  s.files = `git ls-files lib *.md LICENSE`.split("\n")

  s.add_development_dependency "bundler", "~> 2.1"
  s.add_development_dependency "minitest", "~> 5.13.0"
  s.add_development_dependency "standard", "~> 0.11.0"
  s.add_development_dependency "lefthook", "~> 0.7.2"
end
