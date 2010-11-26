# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'service_proxy/version'

Gem::Specification.new do |s|
  s.name = "serviceproxy"
  s.version = ServiceProxy::VERSION
  s.platform = Gem::Platform::RUBY
  s.authors = ['Jeremy Durham']
  s.email = ['jeremydurham@gmail.com']
  s.homepage = 'http://www.onemanwonder.com/projects/serviceproxy'  
  s.summary = 'Lightweight SOAP library for Ruby'
  s.description = 'Lightweight SOAP library for Ruby'

  s.required_rubygems_version = ">= 1.3.6"

  s.add_dependency "nokogiri"

  s.executables = ['wsdl2proxy']
  s.files = `git ls-files`.split("\n")
  s.test_files = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_paths = ["lib"]  
end
