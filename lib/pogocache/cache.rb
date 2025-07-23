class Pogocache::Cache
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
    Pogocache::FFI.pogocache_custom_store(@ptr, key, key.bytesize, value, value.bytesize, (ttl || 0) * 100_000)
  end

  def get(key)
    decode(Pogocache::FFI.pogocache_custom_load(@ptr, key, key.bytesize))
  end

  def delete(key)
    Pogocache::FFI.pogocache_custom_delete(@ptr, key, key.bytesize) == 7
  end

  def self.now
    Pogocache::FFI.pogocache_now / 1_000_000_000
  end

  # Ruby idioms: [] and []= for get/set
  def [](key)
    get(key)
  end

  def []=(key, value)
    set(key, value)
  end

  def fetch(key, &block)
    value = get(key)
    return value.value if value

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

  private

  CALLBACKS = {}

  def new_entry_cb(key)
    callback_id = "#{object_id}_#{key.hash}"
    result_container = {}
    callback = proc do |shard, time, key_ptr, keylen, val_ptr, vallen,
                             expires, flags, cas, update_ptr, udata|
      result_container[:key] = key_ptr.read_bytes(keylen),
        result_container[:value] = decode(val_ptr.read_bytes(vallen)),
        result_container[:expires] = expires,
        result_container[:flags] = flags,
        result_container[:cas] = cas
    end

    CALLBACKS[callback_id] = callback

    [callback, result_container, callback_id]
  end

  def check_result(rc, operation = "operation")
    case rc
    when (0..)
      true
    when -1
      raise CacheError, "#{operation} failed: memory allocation error"
    when -2
      raise CacheError, "#{operation} failed: invalid parameters"
    else
      raise CacheError, "#{operation} failed with code: #{rc}"
    end
  end

  def encode(obj)
    Marshal.dump(obj)
  end

  def decode(str)
    return nil if str.nil? || str.empty?

    Marshal.load(str)
  end
end
