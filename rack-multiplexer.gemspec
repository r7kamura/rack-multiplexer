# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rack/multiplexer/version'

Gem::Specification.new do |spec|
  spec.name          = "rack-multiplexer"
  spec.version       = Rack::Multiplexer::VERSION
  spec.authors       = ["Ryo Nakamura"]
  spec.email         = ["r7kamura@gmail.com"]
  spec.summary       = "Provides a simple router & dispatcher for Rack."
  spec.homepage      = "https://github.com/r7kamura/rack-multiplexer"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "rack"
  spec.add_dependency "rspec", ">= 2.14.1"
  spec.add_development_dependency "activesupport", ">= 3.2.14"
  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "rake"
end
