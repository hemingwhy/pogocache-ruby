module Pogocache::LibraryLoader
  extend FFI::Library

  class << self
    def library_search_paths
      inside_gem = File.join(File.dirname(__FILE__), "..", "..", "ext")
      env_path = [ENV["POGOCACHE_LIB_PATH"]].compact
      system_paths = %w[/usr/local/lib /opt/local/lib /usr/lib64 /usr/lib]

      ([inside_gem] + env_path + system_paths).map do |path|
        File.join(path, "libpogocache.#{FFI::Platform::LIBSUFFIX}")
      end
    end

    def detect_and_load
      lib_name = case FFI::Platform::OS
      when "darwin"
        "libpogocache.dylib"
      when "linux"
        "libpogocache.so"
      else
        raise PlatformNotSupportedError, "Pogocache only supports Linux and macOS (64-bit)"
      end

      search_paths = build_search_paths(lib_name)
      puts search_paths
      begin
        ffi_lib_flags :now, :global
        ffi_lib(search_paths + ["pogocache"])
      rescue LoadError => e
        handle_library_load_error(e, search_paths)
      end
    end

    private

    def build_search_paths(lib_name)
      paths = []

      # Environment override
      paths << ENV["POGOCACHE_LIB_PATH"] if ENV["POGOCACHE_LIB_PATH"]

      # Gem-bundled libraries
      paths << File.join(__dir__, "..", "..", "ext", lib_name)

      # System locations
      paths += %w[/usr/local/lib /opt/local/lib /usr/lib64 /usr/lib].map { |dir| File.join(dir, lib_name) }

      # macOS Homebrew
      if FFI::Platform::IS_MAC
        homebrew_path = begin
          `/usr/bin/brew --prefix 2>/dev/null`.chomp
        rescue
          nil
        end
        paths << File.join(homebrew_path, "lib", lib_name) if homebrew_path
      end

      paths.compact
    end
  end
end
