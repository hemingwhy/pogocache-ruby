class Pogocache::Cache
  def initialize(options = {})
    @extension = Pogocache::Extension.new(Pogocache.configuration.default_opts.merge(options))
  end

  def set(key, value, options = {})
    @extension.store(encode(key), encode(value), options)
  end

  def get(key)
    decode(@extension.load(encode(key))&.dig(:value))
  end

  def entry(key)
    @extension.load(encode(key))&.tap do
      it[:key] = decode(it[:key])
      it[:value] = decode(it[:value])
    end
  end

  def delete(key) = @extension.delete(encode(key))

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

  def increment(key)
    value = get(key)&.to_i
    if value
      set(key, value + 1)
      value + 1
    else
      set(key, 1)
      1
    end
  end

  def decrement(key)
    value = get(key)&.to_i
    if value
      set(key, value - 1)
      value - 1
    else
      set(key, 1)
      1
    end
  end

  def count = @extension.count

  def size = count

  def bytesize = @extension.size

  def clear = @extension.clear

  def sweep = @extension.sweep

  def each(opts = {}, &block)
    if block_given?
      retval = []
      @extension.each(opts) do
        retval << yield(decode(it[:key]), decode(it[:value]))

        Pogocache::ITER_CONTINUE # standard:disable Lint/Void
      end
      retval
    else
      @extension.each(opts)
    end
  end

  def nshards = @extension.nshards

  def cleanup(options = {}) = @extension.sweep

  def prune(options = {})
  end

  def pruning?
    false
  end

  def delete_matched(matcher, options = {})
    @extension.each do |e|
      if decode(e[:key]).to_s.match(matcher)
        Pogocache::ITER_DELETE # standard:disable Lint/Void
      else
        Pogocache::ITER_CONTINUE # standard:disable Lint/Void
      end
    end
  end

  def synchronize
  end

  private

  def encode(obj) = Marshal.dump(obj)

  def decode(str)
    return nil if str.nil? || str.empty?

    Marshal.load(str)
  end
end
