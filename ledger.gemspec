lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ledger/version'

Gem::Specification.new do |s|
  s.name          = 'ledger'
  s.version       = Ledger::VERSION
  s.authors       = ['Cedric Pimenta']
  s.email         = 'contact@cedricpim.com'
  s.homepage      = 'https://github.com/cedricpim/ledger'
  s.description   = 'Simple CLI money tracker'
  s.summary       = 'Quickly create a ledger and manage it from the command line'
  s.license       = 'GPL-3.0'

  s.files         = Dir['lib/**/*', 'spec/**/*', 'bin/*']
  s.executables   = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ['lib']

  s.required_rubygems_version = '>= 1.8.23'
  s.required_ruby_version = '>= 2.2.7'

  s.add_dependency 'command_line_reporter', '~> 4.0.0', '>=3.0'
  s.add_dependency 'money', '~> 6.9.0', '>= 6.9'
  s.add_dependency 'money-open-exchange-rates', '~> 1.0.2', '>= 1.0.2'
  s.add_dependency 'openssl', '~> 2.0.6', '>= 2.0'
  s.add_dependency 'thor', '~> 0.20.0', '>= 0.20'
  s.add_dependency 'xdg', '~> 2.2.3', '>= 2.2'

  s.add_development_dependency 'pry', '~> 0.11.2'
  s.add_development_dependency 'rubocop', '~> 0.51.0'
end
