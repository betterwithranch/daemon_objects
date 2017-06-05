# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'daemon_objects/version'

Gem::Specification.new do |spec|
  spec.name          = "daemon_objects"
  spec.version       = DaemonObjects::VERSION
  spec.authors       = ["Craig Israel"]
  spec.email         = ["craig@theisraels.net"]
  spec.description   = %q{ A light-weight approach to creating and managing daemons in an object-oriented way. Supports any type of daemon, but provides additional support for consuming AMQP queues. }
  spec.summary       = %q{ Daemon objects provides an object-based interface to daemons}
  spec.homepage      = "http://github.com/craigisrael/daemon_objects"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "daemons", "~> 1.1"
  spec.add_dependency "activesupport", "> 5.1"
  spec.add_dependency "bunny", "~> 2.3"
  spec.add_dependency "rake"

  spec.add_development_dependency "rspec", "~> 3.1"
  spec.add_development_dependency "pry-nav"
  spec.add_development_dependency "memory_logger", "~> 0.0.3"
  spec.add_development_dependency "bunny-mock", "~> 1.4"
end
