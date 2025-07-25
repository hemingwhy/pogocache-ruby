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

  def delete(key)
    @extension.delete(encode(key))
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
    @extension.count
  end
  alias_method(:size, :count)

  def bytesize
    @extension.size
  end

  def clear
    @extension.clear
  end

  def sweep
    @extension.sweep
  end

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

  private

  def encode(obj)
    Marshal.dump(obj)
  end

  def decode(str)
    return nil if str.nil? || str.empty?

    Marshal.load(str)
  end
end
