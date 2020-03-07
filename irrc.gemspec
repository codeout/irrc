# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'irrc/version'

Gem::Specification.new do |spec|
  spec.name          = 'irrc'
  spec.version       = Irrc::VERSION
  spec.authors       = ['Shintaro Kojima']
  spec.email         = ['goodies@codeout.net']

  spec.summary       = 'IRR / Whois client to expand as-set and route-set into a list of origin ASs and prefixes'
  spec.description   = 'irrc is a lightweight and flexible client of IRR / Whois Database to expand arbitrary as-set and route-set objects into a list of origin ASs and prefixes belonging to the ASs. It allows concurrent queries to IRR / Whois Databases for performance.'
  spec.homepage      = 'https://github.com/codeout/irrc'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'net-telnet'

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency 'rake', '~> 12.3'
  spec.add_development_dependency 'rspec'
  spec.required_ruby_version = '>= 2.0.0'
end
