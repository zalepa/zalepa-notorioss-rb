module Notorioss
  class Package
    attr_accessor :type, :name, :version

    def initialize(type, name, version)
      @type = type
      @name = name
      @version = version
    end
  end
end
