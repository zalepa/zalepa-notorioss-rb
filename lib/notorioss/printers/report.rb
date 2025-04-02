# frozen_string_literal: true

require "terminal-table"
require "rainbow"

module Notorioss
  module Printers
    # A categorical license reporter
    module Report
      def self.types(licenses)
        types = licenses.map(&:type)
        types.uniq!
      end

      def self.table
        @table ||= Terminal::Table.new headings: %w[License Count], style: { border: :markdown }
      end

      def self.header
        "\n# NotoriOSS Found the following licenses\n\n#{table}\n"
      end

      def self.summarize(licenses, label)
        out = "\n\nWe found the following #{label} libraries:"
        types(licenses).each do |t|
          pkgs = licenses.filter { _1.type == t }
          out += "\n### #{t} (#{pkgs.count})\n"
          pkgs.each { out += "* #{_1.formatted_name}\n" }
        end
        out
      end

      def self.risk(label, level, licenses)
        relevant = licenses.filter { _1.risk == level }

        out = "\n## #{label} Analysis\n"

        out += if relevant.count.positive?
                 summarize(relevant, label)
               else
                 "\n\nWe did not find any clearly #{label} libraries."
               end

        out
      end

      def self.risk_analysis(licenses)
        risk("high-risk", :high, licenses) +
          risk("medium-risk", :medium, licenses) +
          risk("low-risk", :low, licenses) +
          risk("unknown", :unknown, licenses)
      end

      def self.print(licenses)
        types(licenses).each do |t|
          table.add_row [t, licenses.filter { _1.type == t }.count]
        end

        puts header
        puts risk_analysis(licenses)
      end
    end
  end
end
