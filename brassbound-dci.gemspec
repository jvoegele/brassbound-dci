# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require 'brassbound/version'

Gem::Specification.new do |s|
  s.name        = "brassbound-dci"
  s.version     = Brassbound::VERSION
  s.authors     = ["Jason Voegele"]
  s.email       = ["jason@jvoegele.com"]
  s.homepage    = ""
  s.summary     = "Simple but strict DCI framework"
  s.description = "Brassbound is a simple but strict implementation of the Data, Context, and Interaction (DCI) paradigm for Ruby."

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  # s.add_development_dependency "rspec"
  # s.add_runtime_dependency "rest-client"
end
