# -*- encoding: utf-8 -*-

$:.push File.expand_path("../lib", __FILE__)
require 'brassbound/version'
require 'rake'

Gem::Specification.new do |s|
  s.name        = "brassbound-dci"
  s.version     = Brassbound::VERSION
  s.authors     = ["Jason Voegele"]
  s.email       = ["jason@jvoegele.com"]
  s.homepage    = "https://github.com/jvoegele/brassbound-dci"
  s.summary     = "Simple but strict DCI framework"
  s.description = "Brassbound is a simple but strict implementation of the Data, Context, and Interaction (DCI) paradigm for Ruby."
  s.has_rdoc    = true

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency 'rspec', '~> 2.10.0'
end
