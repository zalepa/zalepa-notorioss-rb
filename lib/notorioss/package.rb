# frozen_string_literal: true

module Notorioss
  # An open source gem
  class Package
    HIGH_RISK = /^(GPL-)/i
    MEDIUM_RISK = /^(LGPL-|Apache-)/i
    LOW_RISK = /^(MIT|BSD-.-Clause)/i
    attr_accessor :type, :name, :version, :authors, :full_gem_path

    def initialize(options = {})
      @type = options[:type]
      @name = options[:name]
      @version = options[:version]
      @authors = options[:authors]
      @license_text = options[:license_text]
      @full_gem_path = options[:full_gem_path]
      yield(self) if block_given?
    end

    def formatted_name
      "#{@name} (#{@version})"
    end

    def self.from_spec(spec)
      new do |p|
        p.type          = spec.license || "unknown"
        p.name          = spec.name
        p.version       = spec.version
        p.authors       = spec.authors
        p.full_gem_path = spec.full_gem_path
      end
    end

    def risk
      return @risk unless @risk.nil?

      @risk = :unknown
      @risk = :high if @type.match? HIGH_RISK
      @risk = :medium if @type.match? MEDIUM_RISK
      @risk = :low if @type.match? LOW_RISK
      @risk
    end

    # TODO: check README for license text
    # TODO: checking inconsistent license placement
    def license_text
      return @license_text unless @license_text.nil?

      glob_pattern = File.join(@full_gem_path, "{#{patterns.join(",")}}")
      license_file = Dir[glob_pattern].first

      @license_text = "No license text found, check repository to confirm"
      @license_text = File.read(license_file) if license_file

      @license_text
    end

    def self.patterns
      %w[
        *-license license license.txt license.md
        *-LICENSE LICENSE LICENSE.txt LICENSE.md
        COPYING NOTICE NOTICE.txt
      ]
    end
  end
end
