# -*- encoding: utf-8 -*-

$:.unshift(File.dirname(__FILE__) + '/lib')
require 'knife-vsphere/version'

Gem::Specification.new do |s|
  s.name = 'knife-vsphere'
  s.version = KnifeVsphere::VERSION
  s.summary = 'vSphere Support for Knife'

  s.required_rubygems_version = Gem::Requirement.new('>= 0') if s.respond_to? :required_rubygems_version=

  s.authors = 'Ezra Pagel'
  s.description = "VMware vSphere Support for Chef's Knife Command"
  s.email = 'ezra@cpan.org'
  s.files = Dir['lib/**/*']
  s.rubygems_version = '1.6.2'
  s.homepage = 'http://github.com/ezrapagel/knife-vsphere'
  s.license = 'Apache'
  s.add_dependency('filesize', ['~> 0.1.1'])
  s.add_dependency('netaddr', ['~> 1.5'])
  s.add_dependency('rbvmomi', ['~> 1.8'])
  s.add_dependency('knife-windows', ['>= 0.6.0'])

  s.add_development_dependency('chef', ['>= 0.10.0'])
  s.add_development_dependency('rspec')
  s.add_development_dependency('rake')
end
