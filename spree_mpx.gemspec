Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'spree_mpx'
  s.version     = '1.0.8'
  s.summary     = 'Data export from spree to mpx'
  #s.description = 'Add (optional) gem description here'
  s.required_ruby_version = '>= 1.9.2'

  s.author            = ''
  s.email             = 'jeff.mcfadden@desiringgod.org'
  s.homepage          = 'http://www.desiringgod.org'
  # s.rubyforge_project = 'actionmailer'

  s.files        = Dir['CHANGELOG', 'README.md', 'LICENSE', 'lib/**/*', 'app/**/*']
  s.require_path = 'lib'
  s.requirements << 'rubyzip'

  s.add_dependency('spree_core', '>= 0.50.0')
  s.add_dependency('rubyzip' )
end
