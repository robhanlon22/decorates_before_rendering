# -*- encoding: utf-8 -*-
require File.expand_path('../lib/decorates_before_rendering/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Rob Hanlon"]
  gem.email         = ["rob@mediapiston.com"]
  gem.description   = %q{Small add-on for Draper that decorates models before rendering.}
  gem.summary       = %q{Small add-on for Draper that decorates models before rendering.}
  gem.homepage      = "http://github.com/ohwillie/decorates_before_rendering"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "decorates_before_rendering"
  gem.require_paths = ["lib"]
  gem.version       = DecoratesBeforeRendering::VERSION

  gem.add_development_dependency 'rspec', '>= 2.10.0'
  gem.add_development_dependency 'rbx-require-relative', '>= 0.0.9'

  gem.add_dependency 'activesupport', '>= 3.2.6'
end
