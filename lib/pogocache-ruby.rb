# frozen_string_literal: true

require "ffi"
require_relative "pogocache_ruby"
Pogocache.initialize!(buffer_size: 4096 * 1014)
require_relative "pogocache-ruby/version"
require_relative "pogocache-ruby/platform"
require_relative "pogocache-ruby/ffi"
require_relative "pogocache-ruby/configuration"
require_relative "pogocache-ruby/cache"
require_relative "pogocache-ruby/batch"

module Pogocache
  class Error < StandardError; end

  class PlatformNotSupportedError < Error; end

  class CacheError < Error; end

  class KeyNotFoundError < CacheError; end

  class MemoryError < CacheError; end

  Entry = Struct.new(:key, :value, :expires, :flags, :cas)

  class << self
    def new(options = {})
      Cache.new(options)
    end

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def now
      Cache.now
    end
  end
end
