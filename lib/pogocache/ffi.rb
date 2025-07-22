module Pogocache::FFI
  extend ::FFI::Library

  # ffi_lib ['pogocache', 'libpogocache.so', 'libpogocache.dylib']
  ffi_lib File.dirname(__FILE__) + "/../../ext/pogocache/libpogocache.so"

  EntryCb = callback(:entry_cb, [:int, :int64, :pointer, :size_t, :pointer, :size_t,
    :int64, :uint32, :uint64, :pointer, :pointer], :void)

  DeleteEntryCb = callback(:entry_cb, [:int, :int64, :pointer, :size_t, :pointer, :size_t,
    :int64, :uint32, :uint64, :pointer, :pointer], :bool)

  class DeleteOpts < FFI::Struct
    layout :time, :int64,
      :entry, DeleteEntryCb,
      :udata, :pointer
  end

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
      :entry, DeleteEntryCb,
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

  attach_function :pogocache_delete, [:pointer, :string, :size_t, DeleteOpts.by_ref], :int
  attach_function :pogocache_store, [:pointer, :string, :size_t, :string, :size_t, StoreOpts.by_ref], :int
  attach_function :pogocache_load, [:pointer, :string, :size_t, LoadOpts.by_ref], :int

  attach_function :init_load_buffer, [:size_t], :void
  attach_function :pogo_load, [:pointer, :string, :int64], :string
end
