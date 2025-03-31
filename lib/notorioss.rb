# frozen_string_literal: true

require_relative "notorioss/version"
require "terminal-table"
require "rainbow"
require "optparse"

module Notorioss
  class Error < StandardError; end

  class CLI
    def self.option_parser(options = {})
      @option_parser ||= OptionParser.new do |opts|
        opts.banner = "Usage: notorioss [options]"

        opts.on("-f", "--format FORMAT", %w[table summary json],
                "Output format (table, summary, json)") do |format|
          options[:format] = format
        end

        opts.on("-h", "--help", "Show this help message") do
          puts opts
          exit
        end

        opts.on("-v", "--version", "Show version") do
          puts "Notorioss version #{Notorioss::VERSION}"
          exit
        end
      end
    end

    def self.run(args = ARGV)
      options = {
        format: "table"
      }
      option_parser(options).parse!(args)

      puts "Analyzing Gemfile licenses..."

      require "bundler"

      # Red flag licenses - more restrictive copyleft licenses

      # Orange flag licenses - less restrictive copyleft or with potential compatibility issues

      licenses = {}

      Bundler.definition.specs.each do |spec|
        license = spec.license || "unknown"
        licenses[license] ||= []
        licenses[license] << "#{spec.name} (#{spec.version})"
      end

      output(licenses, options)
    end

    def self.output(licenses, options)
      case options[:format]
      when "table"
        tableize(licenses)
      when "summary"
        summarize(licenses)
      end
    end

    def self.tableize(licenses)
      table = Terminal::Table.new headings: %w[License Count Licenses]

      licenses.keys.each do |license|
        # TEST: highlight red and orange flag licenses
        # Note: this is just a sample, not the final output.
        red_flag_regex = /(?:^|\b)(GPL[-\s]?(?:[23](?:\.0)?)?|GNU\s?(?:General\s?Public\s?License)(?:[-\s][23](?:\.0)?)?|AGPL[-\s]?(?:3(?:\.0)?)?|Affero\s?(?:GPL|General\s?Public\s?License)(?:[-\s]3(?:\.0)?)?|SSPL(?:[-\s]1(?:\.0)?)?|Server\s?Side\s?Public\s?License(?:[-\s]1(?:\.0)?)?|EUPL(?:[-\s][12](?:\.0)?)?|European\s?Union\s?Public\s?License(?:[-\s][12](?:\.0)?)?|CDDL(?:[-\s]1(?:\.0)?)?|Common\s?Development\s?and\s?Distribution\s?License(?:[-\s]1(?:\.0)?)?|OSL(?:[-\s][123](?:\.0)?)?|Open\s?Software\s?License(?:[-\s][123](?:\.0)?)?|CPL(?:[-\s]1(?:\.0)?)?|Common\s?Public\s?License(?:[-\s]1(?:\.0)?)?|EPL[-\s]?1(?:\.0)?|Eclipse\s?Public\s?License[-\s]?1(?:\.0)?|MPL[-\s]?1\.[01]|Mozilla\s?Public\s?License[-\s]?1\.[01]|Reciprocal\s?Public\s?License|RPL)(?:\b|$)/i
        orange_flag_regex = /(?:^|\b)(LGPL[-\s]?(?:[23](?:\.0)?)?|Lesser\s?(?:GPL|General\s?Public\s?License)(?:[-\s][23](?:\.0)?)?|Library\s?General\s?Public\s?License(?:[-\s][23](?:\.0)?)?|MPL[-\s]?2\.0|Mozilla\s?Public\s?License[-\s]?2\.0|EPL[-\s]?2\.0|Eclipse\s?Public\s?License[-\s]?2\.0|CPAL(?:[-\s]1(?:\.0)?)?|Common\s?Public\s?Attribution\s?License(?:[-\s]1(?:\.0)?)?|Artistic[-\s]?License(?:[-\s][12](?:\.0)?)?|CC[-\s]?BY[-\s]?SA(?:[-\s][234]\.0)?|Creative\s?Commons\s?Attribution\s?Share\s?Alike(?:[-\s][234]\.0)?|MS[-\s]?RL|Microsoft\s?Reciprocal\s?License|Sun\s?Public\s?License|SPL|NASA\s?Open\s?Source\s?Agreement|APSL(?:[-\s][12](?:\.0)?)?|Apple\s?Public\s?Source\s?License(?:[-\s][12](?:\.0)?)?)(?:\b|$)/i
        green_flag_regex = /(?:^|\b)(MIT|X11|Expat|BSD[-\s]?(?:[23][-\s]?Clause)?|Apache[-\s]?(?:License[-\s]?)?2(?:\.0)?|ISC|Unlicense|0BSD|Zero[-\s]?BSD|Public[-\s]?Domain|CC0[-\s]?1\.0|Zlib|Python[-\s]?2\.0|WTFPL|Do[-\s]?What[-\s]?The[-\s]?F\*?ck[-\s]?You[-\s]?Want|PostgreSQL|NCSA|BlueOak[-\s]?1\.0|UPL|Universal[-\s]?Permissive[-\s]?License|JSON|Boost[-\s]?Software[-\s]?License|Ruby(?:[-\s]?License)?)(?:\b|$)/i
        license_name = license
        license_name = Rainbow(license_name).bg(:red).white.bold if red_flag_regex.match?(license)
        license_name = Rainbow(license_name).bg(:orange).white.bold if orange_flag_regex.match?(license)
        license_name = Rainbow(license_name).bg(:green).white.bold if green_flag_regex.match?(license)
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
