Gem::Specification.new do |gem|
  gem.name = 'chef-relevant-tests'
  gem.authors = ['Brigade Engineering', 'Tom Dooner']
  gem.email = ['eng@brigade.com', 'tom.dooner@brigade.com']
  gem.homepage = 'https://github.com/brigade/chef-relevant-tests'
  gem.license = 'MIT'

  gem.required_ruby_version = '>= 1.9.3'
  gem.version = '1.0.1'

  gem.executables << 'chef-relevant-tests'
  gem.files = Dir['lib/{,**/}*']

  gem.add_dependency 'chef', '~> 11'
  gem.add_development_dependency 'rspec', '~> 3'

  gem.description = 'Only run the Chef tests that you need to run'
  gem.summary = 'Gem which looks at Chef configuration to narrow which tests you need to run'
end
