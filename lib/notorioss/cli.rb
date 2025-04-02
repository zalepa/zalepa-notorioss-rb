# frozen_string_literal: true

require "thor"
require "bundler"

module Notorioss
  # The CLI client
  class CLI < Thor
    desc "report", "Generate a report"
    option :verbose, type: :boolean
    def report
      pkgs = Bundler.definition.specs.map { Notorioss::Package.from_spec(_1) }
      Notorioss::Printers::Report.print(pkgs)
    end

    desc "notice", "Generate a NOTICE file"
    option :verbose, type: :boolean
    def notice
      pkgs = Bundler.definition.specs.map { Notorioss::Package.from_spec(_1) }
      puts "\n\nNOTICES.txt\n-----------"
      pkgs.each do |license|
        puts "# #{license.formatted_name} - #{license.type}"
        puts "Authors: #{license.authors.join(", ")}"
        puts "#{license.license_text}\n\n"
      end
    end
  end
end
