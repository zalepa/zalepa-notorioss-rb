# frozen_string_literal: true

require "bundler/gem_tasks"
require "minitest/test_task"
require "fileutils"

Minitest::TestTask.create

require "rubocop/rake_task"

RuboCop::RakeTask.new

desc "Remove gem files"
task :clean do
  puts "Removing gem files..."
  FileUtils.rm Dir.glob("*.gem")
end

desc "Build the gem"
task build: [:clean] do
  puts "Building gem..."
  system "gem build notorioss.gemspec"
end

desc "Install the gem locally"
task install: %i[clean build] do
  puts "Installing gem locally..."
  gem_file = Dir.glob("*.gem").first
  system "gem install #{gem_file}"
end

desc "Push the gem to RubyGems"
task push: %i[clean build] do
  puts "Pushing to RubyGems..."
  gem_file = Dir.glob("*.gem").first
  system "gem push #{gem_file}"
end

desc "Full cycle: clean, build, install, and push"
task full_cycle: %i[clean build install push]

task default: %i[test rubocop]
