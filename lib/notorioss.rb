# frozen_string_literal: true

require_relative "notorioss/version"
require "terminal-table"
require "rainbow"

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

      # summarize(licenses)
      tableize(licenses)
    end

    def self.tableize(licenses)
      table = Terminal::Table.new headings: %w[License Count Licenses]

      licenses.keys.each do |license|
        license_name = license
        # TEST: highlight GPL licenses
        # Note: this is just a sample, not the final output.
        license_name = Rainbow(license_name).bg(:red) if license.match(/GPL/)
        table.add_row [license_name, licenses[license].count, licenses[license].sort.join("\n")]
        table.add_separator
      end

      puts table
    end

    def self.summarize(licenses)
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
