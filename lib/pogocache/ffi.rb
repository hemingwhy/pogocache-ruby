module Pogocache::FFI
  extend ::FFI::Library

  ffi_lib File.dirname(__FILE__) + "/../../ext/pogocache/pogocache.so"

  EntryCb = callback(:entry_cb, [:int, :int64, :pointer, :size_t, :pointer, :size_t,
    :int64, :uint32, :uint64, :pointer, :pointer], :void)

  StoreEntryCb = callback(:entry_cb, [:int, :int64, :pointer, :size_t, :pointer, :size_t,
    :int64, :uint32, :uint64, :pointer, :pointer], :bool)

  class StoreOpts < FFI::Struct
    layout :time, :int64,
      :expires, :int64,
      :ttl, :int64,
      :cas, :uint64,
      :flags, :uint32,
      :keepttl, :bool,
      :casop, :bool,
      :nx, :bool,
      :lowmem, :bool,
      :entry, StoreEntryCb,
      :udata, :pointer
  end

  class LoadOpts < FFI::Struct
    layout :time, :int64,
      :notouch, :bool,
      :entry, EntryCb,    # use the defined callback type
      :udata, :pointer
  end

  attach_function :pogocache_new, [:int], :pointer
  attach_function :pogocache_free, [:pointer], :void

  attach_function :pogocache_custom_load, [:pointer, :string, :int64], :string
  attach_function :pogocache_custom_delete, [:pointer, :string, :size_t], :int
  attach_function :pogocache_custom_store, [:pointer, :string, :size_t, :string, :size_t, :int], :int

  attach_function :pogocache_custom_count, [:pointer], :size_t
  attach_function :pogocache_custom_total, [:pointer], :uint64_t
  attach_function :pogocache_custom_size, [:pointer], :size_t
  attach_function :pogocache_now, [], :int64_t

  attach_function :pogocache_custom_keys, [:pointer], :pointer
end
