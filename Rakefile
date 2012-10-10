# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "hostmanager"
  gem.homepage = "http://github.com/edmundhighcock/hostmanager"
  gem.license = "GPLv3"
  gem.summary = %Q{Simple class/command line utility for management of remote hosts.}
  gem.description = %Q{A class and command line utility that allows simple management of ssh hosts and remote folders. E.g. logging in to a remote server becomes as easy as 'hm l y'.}
  gem.email = "github@edmundhighcock.com"
  gem.authors = ["Edmund Highcock"]
	gem.required_ruby_version = '> 1.9.1'
	gem.rdoc_options << '--main' << 'lib/hostmanager.rb'
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

#require 'rcov/rcovtask'
#Rcov::RcovTask.new do |test|
  ##test.libs << 'test'
  ##test.pattern = 'test/**/test_*.rb'
  ##test.verbose = true
  ##test.rcov_opts << '--exclude "gems/*"'
##end

task :default => :test

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "hostmanager #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
