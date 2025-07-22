module Pogocache::FFI
  extend ::FFI::Library
  # ffi_lib ['pogocache', 'libpogocache.so', 'libpogocache.dylib']
  ffi_lib "ext/pogocache/libpogocache.so"

  EntryCb = callback(:entry_cb, [:int, :int64, :pointer, :size_t, :pointer, :size_t,
    :int64, :uint32, :uint64, :pointer, :pointer], :void)

  class PogocacheLoadOpts < FFI::Struct
    layout :time, :int64,
      :notouch, :bool,
      :entry, EntryCb,    # use the defined callback type
      :udata, :pointer
  end

  attach_function :pogocache_new, [:int], :pointer
  attach_function :pogocache_store, [:pointer, :string, :size_t, :string, :size_t, :int64], :int
  # attach_function :pogocache_load, [:pointer, :string, :size_t, :pointer], :int
  attach_function :pogocache_load, [:pointer, :pointer, :size_t, PogocacheLoadOpts.by_ref], :int

  attach_function :pogocache_free, [:pointer], :void
end
