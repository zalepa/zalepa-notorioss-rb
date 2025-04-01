module Notorioss
  class Package
    HIGH_RISK = /^(GPL-)/i
    MEDIUM_RISK = /^(LGPL-|Apache-)/i
    LOW_RISK = /^(MIT|BSD-.-Clause)/i
    attr_accessor :type, :name, :version, :authors, :license_text

    def initialize(type, name, version, authors, license_text)
      @type = type
      @name = name
      @version = version
      @authors = authors
      @license_text = license_text
    end

    def formatted_name
      "#{@name} (#{@version})"
    end

    def risk
      return @risk unless @risk.nil?

      @risk = :unknown
      @risk = :high if @type.match? HIGH_RISK
      @risk = :medium if @type.match? MEDIUM_RISK
      @risk = :low if @type.match? LOW_RISK
      @risk
    end
  end
end
