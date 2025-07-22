# frozen_string_literal: true

require "ffi"
require "debug"
require "base64"
require_relative "pogocache/version"
require_relative "pogocache/errors"
require_relative "pogocache/platform"
require_relative "pogocache/library_loader"
require_relative "pogocache/ffi"
require_relative "pogocache/configuration"
require_relative "pogocache/cache"

# Main module for pogocache Ruby bindings
module Pogocache
  class Error < StandardError; end

  class LibraryNotFoundError < Error; end

  class PlatformNotSupportedError < Error; end

  class CacheError < Error; end

  class KeyNotFoundError < CacheError; end

  class MemoryError < CacheError; end

  Entry = Struct.new(:key, :value, :expires, :flags, :cas)

  class << self
    def check_result(rc, operation = "operation")
      puts "operation returned: #{rc}"
      case rc
      when (0..)
        true
      when -1
        raise CacheError, "#{operation} failed: memory allocation error"
      when -2
        raise CacheError, "#{operation} failed: invalid parameters"
      else
        raise CacheError, "#{operation} failed with code: #{rc}"
      end
    end

    # Create a new cache instance
    # @param options [Hash] Configuration options
    # @return [Pogocache::Cache] New cache instance
    def new(options = {})
      Cache.new(options)
    end

    # Global configuration
    # @return [Pogocache::Configuration]
    def configuration
      @configuration ||= Configuration.new
    end

    # Configure pogocache
    # @yield [config] Configuration instance
    def configure
      yield(configuration)
    end

    def self.create(options = {})
      Cache.new(options)
    end
  end
end
