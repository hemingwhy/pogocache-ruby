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
    return unless @ptr && !@ptr.null?

    Pogocache::FFI.pogocache_free(@ptr)
    @ptr = nil
    ObjectSpace.undefine_finalizer(self)
  end

  def set(key, value, ttl: nil)
    value = encode(value)
    key = encode(key)
    Pogocache::FFI.pogocache_custom_store(@ptr, key, key.bytesize, value, value.bytesize, (ttl || 0) * 100_000)
  end

  def get(key)
    key = encode(key)
    decode(Pogocache::FFI.pogocache_custom_load(@ptr, key, key.bytesize))
  end

  def delete(key)
    key = encode(key)
    Pogocache::FFI.pogocache_custom_delete(@ptr, key, key.bytesize) == 7
  end

  def batch(&block)
    batch = Pogocache::Batch.new(Pogocache::FFI.pogocache_custom_begin(@ptr))
    yield(batch)
    Pogocache::FFI.pogocache_custom_end(batch.ptr)
  end

  def self.now
    Pogocache::FFI.pogocache_now / 1_000_000_000
  end

  def [](key)
    get(key)
  end

  def []=(key, value)
    set(key, value)
  end

  def fetch(key, &block)
    value = get(key)
    return value if value

    block&.call
  end

  def count
    Pogocache::FFI.pogocache_custom_count(@ptr)
  end

  def size
    Pogocache::FFI.pogocache_custom_size(@ptr)
  end

  def total
    Pogocache::FFI.pogocache_custom_total(@ptr)
  end

  def keys
    Pogocache::FFI.pogocache_custom_keys(@ptr)
      .read_array_of_type(:pointer, :read_pointer, count)
      .map { decode(it) }
  end

  def clear
    Pogocache::FFI.pogocache_custom_clear(@ptr)
  end

  def sweep
    res = Pogocache::FFI.pogocache_custom_sweep(@ptr)
    [res.get_int(0), res.get_int(8)]
  end

  private

  def encode(obj)
    Marshal.dump(obj)
  end

  def decode(str)
    return nil if str.null?

    len = str.get_int(0)
    packed = str.get_bytes(8, len)
    Marshal.load(packed)
  end
end
