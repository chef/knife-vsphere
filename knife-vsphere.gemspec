# -*- encoding: utf-8 -*-

$:.unshift(File.dirname(__FILE__) + "/lib")
require "knife-vsphere/version"

Gem::Specification.new do |s|
  s.name = "knife-vsphere"
  s.version = KnifeVsphere::VERSION
  s.summary = "VMware vSphere support for Chef Infra's Knife command"
  s.authors = "Ezra Pagel"
  s.description = "VMware vSphere support for Chef Infra's Knife command"
  s.email = "ezra@cpan.org"
  s.files = Dir["lib/**/*"]
  s.required_ruby_version = ">= 2.5"
  s.homepage = "http://github.com/chef/knife-vsphere"
  s.license = "Apache-2.0"
  s.add_dependency "netaddr", ["~> 1.5"]
  s.add_dependency "rbvmomi", ["~> 1.8"]
  s.add_dependency "filesize", ["~> 0.1.1"]
  s.add_dependency "chef-vault", [">= 2.6.0"]
  s.add_dependency "chef", ">= 15.1"
  s.add_dependency "chef-bin", ">= 15.1"
end
