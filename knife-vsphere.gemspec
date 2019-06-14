# -*- encoding: utf-8 -*-

$:.unshift(File.dirname(__FILE__) + "/lib")
require "knife-vsphere/version"

Gem::Specification.new do |s|
  s.name = "knife-vsphere"
  s.version = KnifeVsphere::VERSION
  s.summary = "vSphere Support for Knife"
  s.authors = "Ezra Pagel"
  s.description = "VMware vSphere Support for Chef's Knife Command"
  s.email = "ezra@cpan.org"
  s.files = Dir["lib/**/*"]
  s.rubygems_version = "1.6.2"
  s.homepage = "http://github.com/chef/knife-vsphere"
  s.license = "Apache-2.0"
  # s.add_dependency "knife-windows", ["~> 1.0"]
  s.add_dependency "netaddr", ["~> 1.5"]
  s.add_dependency "rbvmomi", ["~> 1.8"]
  s.add_dependency "filesize", ["~> 0.1.1"]
  s.add_dependency "chef-vault", [">= 2.6.0"]
end
