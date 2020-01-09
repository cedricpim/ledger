lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ledger/version'

Gem::Specification.new do |s| # rubocop:disable Metrics/BlockLength
  s.name          = 'ledger'
  s.version       = Ledger::VERSION
  s.authors       = ['cedricpim']
  s.email         = 'github.f@cedricpim.com'
  s.homepage      = 'https://github.com/cedricpim/ledger'
  s.description   = 'Simple CLI money tracker'
  s.summary       = 'Quickly create a ledger and manage it from the command line'
  s.license       = 'GPL-3.0'

  s.files         = Dir['lib/**/*', 'spec/**/*', 'bin/*', 'config/*']
  s.executables   = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ['lib']

  s.required_rubygems_version = '>= 1.8.23'
  s.required_ruby_version = '>= 2.7'

  s.add_dependency 'bigdecimal', '~> 2.0.0'
  s.add_dependency 'command_line_reporter', '~> 4.0.1'
  s.add_dependency 'faraday', '~> 0.17.3'
  s.add_dependency 'money', '~> 6.13.7'
  s.add_dependency 'money-open-exchange-rates', '~> 1.3.0'
  s.add_dependency 'nokogiri', '~> 1.10.7'
  s.add_dependency 'openssl', '~> 2.1.2'
  s.add_dependency 'thor', '~> 1.0.1'
  s.add_dependency 'xdg', '~> 4.0.0'

  s.add_development_dependency 'factory_bot'
  s.add_development_dependency 'guard'
  s.add_development_dependency 'guard-rspec'
  s.add_development_dependency 'pry'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'rubocop'
  s.add_development_dependency 'vcr'
end
