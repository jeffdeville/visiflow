# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'visiflow/version'

Gem::Specification.new do |spec|
  spec.name          = "visiflow"
  spec.version       = Visiflow::VERSION
  spec.authors       = ["Jeff Deville"]
  spec.email         = ["jeffdeville@gmail.com"]
  spec.summary       = %q{Workflows in Ruby.}
  spec.description   = %q{ Simple, no state-machine over-engineering. Unopinionated.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
  spec.add_development_dependency 'rspec', '~> 2.14'
  spec.add_development_dependency 'fuubar'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'pry-nav'
end
