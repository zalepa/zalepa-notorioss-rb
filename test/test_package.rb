# frozen_string_literal: true

require "ostruct"
require "test_helper"
require "bundler"

class TestPackage < Minitest::Test
  def setup
    @pkg = Notorioss::Package.new do |p|
      p.type = "MIT"
      p.name = "test"
      p.version = "0.3"
      p.authors = "John Doe"
      p.license_text = "stub"
    end
  end

  def test_formatted_name
    assert_equal "test (0.3)", @pkg.formatted_name
  end

  def test_it_allows_hash_parameters
    @pkg = Notorioss::Package.new(type: "MIT", name: "test", version: "0.3", authors: "John Doe", license_text: "stub")
    refute @pkg.nil?
  end

  def test_it_allows_initialization_from_bundler_spec_object
    pp Bundler.definition.specs.first
    o = OpenStruct.new(license: "MIT", name: "test", version: "0.3", authors: "John Doe", full_gem_path: "/")
    @pkg = Notorioss::Package.from_spec(o)
    refute @pkg.nil?
    assert_equal "MIT", @pkg.type
    assert_nil @pkg.license_text
  end
end
