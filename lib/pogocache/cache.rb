require "base64"
class Pogocache::Cache
  include Enumerable

  def initialize(options = {})
    @ptr = Pogocache::FFI.pogocache_new(options[:max_size] || 0)
    raise MemoryError, "Failed to create cache instance" if @ptr.null?
    @callbacks = []

    ObjectSpace.define_finalizer(self, self.class.finalizer(@ptr, Process.pid))
  end

  def self.finalizer(ptr, pid)
    proc do
      Pogocache::FFI.pogocache_free(ptr) if Process.pid == pid
    end
  end

  def close
    if @ptr && !@ptr.null?
      Pogocache::FFI.pogocache_free(@ptr)
      @ptr = nil
      ObjectSpace.undefine_finalizer(self)
    end
  end

  def set(key, value, ttl: nil)
    value = Base64.strict_encode64(Marshal.dump(value))

    result = Pogocache::FFI.pogocache_store(@ptr, key, key.bytesize, value, value.bytesize, ttl || 0)
    Pogocache.check_result(result, "set operation")
  end

  def get(key)
    # Define the callback
    entry_cb = proc do |shard, time, key_ptr, keylen, val_ptr, vallen,
                             expires, flags, cas, update_ptr, udata|
      result = {
        key: key_ptr.read_bytes(keylen),
        value: Marshal.load(Base64.strict_decode64(val_ptr.read_bytes(vallen))),
        expires: expires,
        flags: flags,
        cas: cas
      }

      dump = Marshal.dump(result)
      buffer = FFI::MemoryPointer.new(:char, dump.bytesize + 8)
      buffer.put_bytes(0, [dump.bytesize].pack("Q"))
      buffer.put_bytes(8, dump)

      udata.put_pointer(0, buffer)
    end

    result_ptr = FFI::MemoryPointer.new(:pointer)

    opts = Pogocache::FFI::PogocacheLoadOpts.new
    opts[:time] = 0
    opts[:notouch] = false
    opts[:entry] = entry_cb
    opts[:udata] = result_ptr

    key_buf = FFI::MemoryPointer.from_string(key.to_s)
    res = Pogocache::FFI.pogocache_load(@ptr, key_buf, key.bytesize, opts)

    puts "res = #{res}"

    if res == 3
      r = result_ptr.read_pointer
      size = r.get_int64(0)
      dumped = r.get_bytes(8, size)
      Pogocache::Entry.new(**Marshal.load(dumped))
    end
  end

  # Ruby idioms: [] and []= for get/set
  def [](key)
    get(key).value
  end

  def []=(key, value)
    set(key, value)
  end

  # Block-based operations
  def fetch(key, &block)
    value = get(key)
    return value.value if value
    block&.call
  end

  # Enumerable support
  def each
    return enum_for(:each) unless block_given?
    keys.each { |key| yield [key, get(key)] }
  end

  CALLBACKS = {}  # Prevent GC

  private

  def create_load_callback(key)
    callback_id = "#{object_id}_#{key.hash}"
    result_container = {}

    callback = FFI::Function.new(:void, [:int, :int64, :pointer, :size_t, :pointer, :size_t, :int64, :uint32, :uint64, :pointer, :pointer]) do |shard, time, key_ptr, keylen, value_ptr, valuelen, expires, flags, cas, update_ptr, udata|
      puts "DEBUG: load callback"
      unless value_ptr.null?
        result_container[:value] = value_ptr.read_string(valuelen)
        result_container[:expires] = expires
      end
    rescue => e
      # Never let exceptions escape callbacks
      warn "Callback error: #{e.message}"
      result_container[:error] = e
    end

    CALLBACKS[callback_id] = callback
    [callback, result_container, callback_id]
  end
end
