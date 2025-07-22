class Pogocache::Cache
  include Enumerable

  def initialize(options = {})
    @ptr = Pogocache::FFI.pogocache_new(options[:max_size] || 0)
    raise MemoryError, "Failed to create cache instance" if @ptr.null?

    @callbacks = []

    ObjectSpace.define_finalizer(self, self.class.finalizer(@ptr, Process.pid))
    Pogocache::FFI.init_load_buffer(1024*1024)
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
    opts = Pogocache::FFI::StoreOpts.new
    opts[:ttl] = ttl * 100_000 if ttl

    result = Pogocache::FFI.pogocache_store(@ptr, key, key.bytesize, value, value.bytesize, opts)
    check_result(result, "set operation")
  end

  def get(key)
    decode(Pogocache::FFI.pogo_load(@ptr, key, key.bytesize))
  end

  def delete(key)
    FFI::MemoryPointer.from_string(key.to_s)
    opts = Pogocache::FFI::DeleteOpts.new
    opts[:time] = 0
    new_entry_cb(key)
    opts[:entry] = proc { |a, b, c, d, e, f, g, h, i, j, k| true }
    result = Pogocache::FFI.pogocache_delete(@ptr, key, key.bytesize, opts)
    check_result(result, "delete operation")
  end

  # Ruby idioms: [] and []= for get/set
  def [](key)
    get(key)
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

  private

  CALLBACKS = {} # Prevent GC

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
