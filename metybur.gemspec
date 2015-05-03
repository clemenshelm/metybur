# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'metybur/version'

Gem::Specification.new do |spec|
  spec.name          = "metybur"
  spec.version       = Metybur::VERSION
  spec.authors       = ["Clemens Helm"]
  spec.email         = ["clemens.helm@gmail.com"]
  spec.summary       = 'DDP client for Ruby to connect to Meteor apps.'
  spec.description   = <<-description
    Metybur lets your Ruby application connect to a Meteor app. It allows you
    to subscribe to collections and to receive updates on them.
    You can also call Meteor methods from Ruby.
  description
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
end
