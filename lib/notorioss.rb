# frozen_string_literal: true

require_relative "notorioss/version"
require_relative "notorioss/package"
require "terminal-table"
require "rainbow"
require "optparse"
require "bundler"

module Notorioss
  class Error < StandardError; end

  class CLI
    def self.option_parser(options = {})
      @option_parser ||= OptionParser.new do |opts|
        opts.banner = "Usage: notorioss [options]"

        opts.on("-f", "--format FORMAT", %w[table summary report], "Output format (table, summary, report)") do |format|
          options[:format] = format
        end

        opts.on("-n", "--notice", "Generate a NOTICE file in the current directory") do
          options[:notice] = true
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
      options = { format: "table", notice: false }
      option_parser(options).parse!(args)

      licenses = []

      Bundler.definition.specs.each do |spec|
        license_file = Dir[File.join(spec.full_gem_path,
                                     "{*-license, license,license.txt,license.md, *-LICENSE, LICENSE,LICENSE.txt,LICENSE.md,COPYING,NOTICE,NOTICE.txt}")].first
        license_text = File.read(license_file) if license_file

        # TODO: check README for license text
        # TODO: checking inconsistent license placement

        licenses << Notorioss::Package.new(spec.license || "unknown", spec.name, spec.version, spec.authors,
                                           license_text)
      end

      output(licenses, options)

      generate_notices(licenses) if options[:notice]
    end

    def self.generate_notices(licenses)
      licenses.each do |license|
        # next unless license.license_text.nil? # for debugging

        puts "# #{license.formatted_name}"
        puts "Authors: #{license.authors.join(", ")}"
        puts license.license_text
      end
    end

    def self.output(licenses, options)
      case options[:format]
      when "table"
        tableize(licenses)
      when "summary"
        summarize(licenses)
      when "report"
        reportize(licenses)
      end
    end

    def self.reportize(licenses)
      table = Terminal::Table.new headings: %w[License Count], style: { border: :markdown }

      types = licenses.map { _1.type }.uniq

      types.each do |t|
        table.add_row [t, licenses.filter { _1.type == t }.count]
      end

      puts "# NotoriOSS Found the following licenses"
      puts table

      puts "\n## High-Risk Analysis\n"

      high_risk = licenses.filter { _1.risk == :high }

      if high_risk.count.positive?
        puts "\n\nWe found the following high-risk libraries:"
        types = high_risk.map { _1.type }.uniq
        types.each do |t|
          pkgs = high_risk.filter { _1.type == t }
          puts "\n### #{t} (#{pkgs.count})"
          pkgs.each { puts "* #{_1.formatted_name}" }
        end
      else
        puts "\n\nWe did not find any clearly high-risk libraries."
      end

      puts "\n## Medium-Risk Analysis\n"

      medium_risk = licenses.filter { _1.risk == :medium }

      if medium_risk.count.positive?
        puts "\n\nWe found the following medium-risk libraries:"
        types = medium_risk.map { _1.type }.uniq
        types.each do |t|
          pkgs = medium_risk.filter { _1.type == t }
          puts "\n### #{t} (#{pkgs.count})"
          pkgs.each { puts "* #{_1.formatted_name}" }
        end
      else
        puts "\n\nWe did not find any clearly medium-risk libraries."
      end

      puts "\n## Low-Risk Analysis\n"

      low_risk = licenses.filter { _1.risk == :low }

      if low_risk.count.positive?
        puts "\n\nWe found the following low-risk libraries:"
        types = low_risk.map { _1.type }.uniq
        types.each do |t|
          pkgs = low_risk.filter { _1.type == t }
          puts "\n### #{t} (#{pkgs.count})"
          pkgs.each { puts "* #{_1.formatted_name}" }
        end
      else
        puts "\n\nWe did not find any clearly low-risk libraries."
      end

      puts "\n## Unknown Risk Analysis\n"

      unknown_risk = licenses.filter { _1.risk == :unknown }

      if unknown_risk.count.positive?
        puts "\n\nWe found the following unknown libraries:"
        types = unknown_risk.map { _1.type }.uniq
        types.each do |t|
          pkgs = unknown_risk.filter { _1.type == t }
          puts "\n### #{t} (#{pkgs.count})"
          pkgs.each { puts "* #{_1.formatted_name}" }
        end
      else
        puts "\n\nWe did not find any unknown libraries."
      end
    end

    def self.tableize(licenses)
      table = Terminal::Table.new headings: %w[License Count Licenses], style: { all_separators: true }

      types = licenses.map { _1.type }.uniq

      types.each do |type|
        # TEST: highlight red and orange flag licenses
        # Note: this is just a sample, not the final output.
        # This should probably be moved into Package
        red_flag_regex = /(?:^|\b)(GPL[-\s]?(?:[23](?:\.0)?)?|GNU\s?(?:General\s?Public\s?License)(?:[-\s][23](?:\.0)?)?|AGPL[-\s]?(?:3(?:\.0)?)?|Affero\s?(?:GPL|General\s?Public\s?License)(?:[-\s]3(?:\.0)?)?|SSPL(?:[-\s]1(?:\.0)?)?|Server\s?Side\s?Public\s?License(?:[-\s]1(?:\.0)?)?|EUPL(?:[-\s][12](?:\.0)?)?|European\s?Union\s?Public\s?License(?:[-\s][12](?:\.0)?)?|CDDL(?:[-\s]1(?:\.0)?)?|Common\s?Development\s?and\s?Distribution\s?License(?:[-\s]1(?:\.0)?)?|OSL(?:[-\s][123](?:\.0)?)?|Open\s?Software\s?License(?:[-\s][123](?:\.0)?)?|CPL(?:[-\s]1(?:\.0)?)?|Common\s?Public\s?License(?:[-\s]1(?:\.0)?)?|EPL[-\s]?1(?:\.0)?|Eclipse\s?Public\s?License[-\s]?1(?:\.0)?|MPL[-\s]?1\.[01]|Mozilla\s?Public\s?License[-\s]?1\.[01]|Reciprocal\s?Public\s?License|RPL)(?:\b|$)/i
        orange_flag_regex = /(?:^|\b)(LGPL[-\s]?(?:[23](?:\.0)?)?|Lesser\s?(?:GPL|General\s?Public\s?License)(?:[-\s][23](?:\.0)?)?|Library\s?General\s?Public\s?License(?:[-\s][23](?:\.0)?)?|MPL[-\s]?2\.0|Mozilla\s?Public\s?License[-\s]?2\.0|EPL[-\s]?2\.0|Eclipse\s?Public\s?License[-\s]?2\.0|CPAL(?:[-\s]1(?:\.0)?)?|Common\s?Public\s?Attribution\s?License(?:[-\s]1(?:\.0)?)?|Artistic[-\s]?License(?:[-\s][12](?:\.0)?)?|CC[-\s]?BY[-\s]?SA(?:[-\s][234]\.0)?|Creative\s?Commons\s?Attribution\s?Share\s?Alike(?:[-\s][234]\.0)?|MS[-\s]?RL|Microsoft\s?Reciprocal\s?License|Sun\s?Public\s?License|SPL|NASA\s?Open\s?Source\s?Agreement|APSL(?:[-\s][12](?:\.0)?)?|Apple\s?Public\s?Source\s?License(?:[-\s][12](?:\.0)?)?)(?:\b|$)/i
        green_flag_regex = /(?:^|\b)(MIT|X11|Expat|BSD[-\s]?(?:[23][-\s]?Clause)?|Apache[-\s]?(?:License[-\s]?)?2(?:\.0)?|ISC|Unlicense|0BSD|Zero[-\s]?BSD|Public[-\s]?Domain|CC0[-\s]?1\.0|Zlib|Python[-\s]?2\.0|WTFPL|Do[-\s]?What[-\s]?The[-\s]?F\*?ck[-\s]?You[-\s]?Want|PostgreSQL|NCSA|BlueOak[-\s]?1\.0|UPL|Universal[-\s]?Permissive[-\s]?License|JSON|Boost[-\s]?Software[-\s]?License|Ruby(?:[-\s]?License)?)(?:\b|$)/i

        licenses_of_type = licenses.filter { _1.type == type }

        type = Rainbow(type).bg(:red).white.bold if red_flag_regex.match?(type)
        type = Rainbow(type).bg(:orange).white.bold if orange_flag_regex.match?(type)
        type = Rainbow(type).bg(:green).white.bold if green_flag_regex.match?(type)

        table.add_row [type, licenses_of_type.count, licenses_of_type.map { "#{_1.name} (#{_1.version})" }.join("\n")]
      end

      puts table
    end

    def self.summarize(licenses)
      puts "\nLicense Summary:"
      puts "----------------"

      types = licenses.map { _1.type }.uniq

      types.each do |type|
        gems = licenses.filter { _1.type == type }
        puts "\n#{type}:"
        gems.each do |gem|
          puts "  - #{gem.name} (#{gem.version})"
        end
      end

      # puts "\nTotal: #{Bundler.definition.specs.count} gems across #{licenses.keys.count} licenses"
    end
  end
end
