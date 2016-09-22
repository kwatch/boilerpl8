# -*- coding: utf-8 -*-

Gem::Specification.new do |spec|
  spec.name            = 'boilerpl8'
  spec.version         = '$Release: 0.1.0 $'.split()[1]
  spec.author          = 'makoto kuwata'
  spec.email           = 'kwa@kuwata-lab.com'
  spec.platform        = Gem::Platform::RUBY
  spec.homepage        = 'https://github.com/kwatch/boilerpl8/tree/ruby'
  spec.summary         = "download and expand boilerplate files"
  spec.description     = <<-'END'
Scaffolding tool to download and expand boilerplate files.
END
  spec.license         = 'MIT'
  spec.files           = Dir[*%w[
                           README.md MIT-LICENSE Rakefile boilerpl8.gemspec
                           bin/*
                           lib/**/*.rb
                           test/**/*.rb
                         ]]
  spec.executables     = ['boilerpl8']
  spec.bindir          = 'bin'
  spec.require_path    = 'lib'
  spec.test_files      = Dir['test/**/*_test.rb']

  spec.add_development_dependency 'minitest'
  spec.add_development_dependency 'minitest-ok'
end
