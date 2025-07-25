# frozen_string_literal: true

module Pogocache
  # Platform detection and compatibility checking
  module Platform
    extend self

    SUPPORTED_OS = %w[darwin linux].freeze
    SUPPORTED_ARCH = %w[x86_64 arm64].freeze

    def supported?
      SUPPORTED_OS.include?(os) && SUPPORTED_ARCH.include?(arch)
    end

    def os
      @os ||= case RbConfig::CONFIG["host_os"]
      when /darwin|mac os/
        "darwin"
      when /linux/
        "linux"
      else
        RbConfig::CONFIG["host_os"]
      end
    end

    def arch
      @arch ||= case RbConfig::CONFIG["host_cpu"]
      when /x86_64|amd64/
        "x86_64"
      when /arm64|aarch64/
        "arm64"
      else
        RbConfig::CONFIG["host_cpu"]
      end
    end

    def library_name
      @library_name ||= begin
        base = "pogocache_ruby"
        case os
        when "darwin"
          "#{base}.bundle"
        when "linux"
          "#{base}.so"
        else
          raise PlatformNotSupportedError, "Unsupported OS: #{os}"
        end
      end
    end

    def check_compatibility!
      unless supported?
        raise PlatformNotSupportedError,
          "Pogocache only supports 64-bit Linux and macOS. " \
          "Current platform: #{os}/#{arch}"
      end
    end
  end
end
