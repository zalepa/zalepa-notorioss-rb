# frozen_string_literal: true

require_relative "notorioss/version"

module Notorioss
  class Error < StandardError; end

  class CLI
    def self.run
      puts "Analyzing Gemfile licenses..."

      require "bundler"

      licenses = {}

      Bundler.definition.specs.each do |spec|
        license = spec.license || "unknown"
        licenses[license] ||= []
        licenses[license] << "#{spec.name} (#{spec.version})"
      end

      puts "\nLicense Summary:"
      puts "----------------"

      licenses.each do |license, gems|
        puts "\n#{license}:"
        gems.sort.each do |gem|
          puts "  - #{gem}"
        end
      end

      puts "\nTotal: #{Bundler.definition.specs.count} gems across #{licenses.keys.count} licenses"
    end
  end
end
