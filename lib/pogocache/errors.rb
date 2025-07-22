# frozen_string_literal: true

module Pogocache
  # Base error class for all pogocache errors
  class Error < StandardError; end

  # Raised when the pogocache library cannot be found
  class LibraryNotFoundError < Error; end

  # Raised when running on an unsupported platform
  class PlatformNotSupportedError < Error; end

  # Base class for cache operation errors
  class CacheError < Error; end

  # Raised when a key is not found
  class KeyNotFoundError < CacheError; end

  # Raised when memory allocation fails
  class MemoryError < CacheError; end

  # Raised when an operation times out
  class TimeoutError < CacheError; end

  # Raised for invalid arguments
  class ArgumentError < CacheError; end
end
