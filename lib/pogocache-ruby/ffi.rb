module Pogocache::FFI
  extend ::FFI::Library

  ffi_lib File.dirname(__FILE__) + "/../pogocache_ruby.so"

  attach_function :pogocache_new, [:int], :pointer
  attach_function :pogocache_free, [:pointer], :void
  attach_function :pogocache_custom_sweep, [:pointer], :pointer

  attach_function :pogocache_custom_load, [:pointer, :pointer, :size_t], :pointer
  attach_function :pogocache_custom_delete, [:pointer, :pointer, :size_t], :int
  attach_function :pogocache_custom_store, [:pointer, :pointer, :size_t, :pointer, :size_t, :int], :int

  attach_function :pogocache_custom_count, [:pointer], :size_t
  attach_function :pogocache_custom_total, [:pointer], :uint64_t
  attach_function :pogocache_custom_size, [:pointer], :size_t
  attach_function :pogocache_now, [], :int64_t

  attach_function :pogocache_custom_keys, [:pointer], :pointer
  attach_function :pogocache_custom_clear, [:pointer], :void

  attach_function :pogocache_custom_begin, [:pointer], :pointer
  attach_function :pogocache_custom_end, [:pointer], :void
end
