$:.push File.expand_path('../lib', __FILE__)
require 'civic-summary/version'

Gem::Specification.new do |s|
  s.name          = 'civic-summary'
  s.version       = CivicSummary::VERSION
  s.date          = '2016-07-25'
  s.summary       = "Build tool for generating the Genome Model Tools site"
  s.description   = "Build tool for generating the Genome Model Tools site from data stored on Github"
  s.authors       = ["Adam Coffman"]
  s.email         = 'acoffman@wustl.edu'
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- spec/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  s.homepage      = 'https://github.com/acoffman/civic-summary'
  s.license       = 'MIT'

  s.add_runtime_dependency('gruff', '~> 0.7.0')
end
