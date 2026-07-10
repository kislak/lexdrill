# frozen_string_literal: true

require_relative "lib/lexdrill/version"

Gem::Specification.new do |spec|
  spec.name = "lexdrill"
  spec.version = Lexdrill::VERSION
  spec.authors = ["Siarhei Kisliak"]
  spec.email = ["kislak7@gmail.com"]

  spec.summary = "Vocabulary drilling in your terminal."
  spec.description = "lexdrill prints a vocabulary word or phrase on demand, tracking how often " \
                     "each one has been shown."
  spec.homepage = "https://github.com/kislak/lexdrill"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.chdir(__dir__) do
    Dir["lib/**/*.rb"] + Dir["bin/*"] + %w[README.md LICENSE.txt lexdrill.gemspec Gemfile]
  end
  spec.bindir = "bin"
  spec.executables = ["lexdrill"]
  spec.require_paths = ["lib"]
end
