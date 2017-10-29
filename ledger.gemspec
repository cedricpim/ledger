lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ledger/version'

Gem::Specification.new do |s|
  s.name          = 'ledger'
  s.version       = Ledger::VERSION
  s.authors       = ['Cedric Pimenta']
  s.description   = 'Simple CLI money tracker'
  s.summary       = 'Simple CLI money tracker'
  s.license       = 'GPL-3.0'

  s.files         = Dir['lib/**/*', 'spec/**/*', 'bin/*']
  s.executables   = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ['lib']

  s.required_rubygems_version = '>= 1.8.23'
  s.required_ruby_version = '>= 2.2.7'

  s.add_dependency 'colorize'
  s.add_dependency 'google_currency'
  s.add_dependency 'money'
  s.add_dependency 'openssl'
  s.add_dependency 'terminal-table'

  s.add_development_dependency 'pry'
  s.add_development_dependency 'rubocop'
end
