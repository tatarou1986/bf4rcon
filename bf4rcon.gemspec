# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'bf4rcon/version'

Gem::Specification.new do |spec|
  spec.name          = "bf4rcon"
  spec.version       = Bf4rcon::VERSION
  spec.authors       = ["Kazushi Takahashi"]
  spec.email         = ["kazushi@rvm.jp"]
  spec.summary       = %q{EA Battlefield 4 RCON Protocol implemented in Ruby 2.0.0.}
  spec.description   = %q{EA Battlefield 4 RCON Protocol implemented in Ruby 2.0.0.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "bindata"                      
  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "rake"
end
