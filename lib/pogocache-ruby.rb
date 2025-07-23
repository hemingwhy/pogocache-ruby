# frozen_string_literal: true

require "ffi"
require_relative "pogocache-ruby/version"
require_relative "pogocache-ruby/errors"
require_relative "pogocache-ruby/platform"
require_relative "pogocache-ruby/library_loader"
require_relative "pogocache-ruby/ffi"
require_relative "pogocache-ruby/configuration"
require_relative "pogocache-ruby/cache"

module Pogocache
  class Error < StandardError; end

  class LibraryNotFoundError < Error; end

  class PlatformNotSupportedError < Error; end

  class CacheError < Error; end

  class KeyNotFoundError < CacheError; end

  class MemoryError < CacheError; end

  Entry = Struct.new(:key, :value, :expires, :flags, :cas)

  class << self
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

    def now
      Cache.now
    end
  end
end
