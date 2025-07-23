> Work in progress...

# Pogocache::Ruby

Ruby bindings for [pogocache](https://github.com/tidwall/pogocache).

Currently only Linux is supported.


## Benchmark

```ruby
require 'pogocache'
require 'active_support'
require 'active_support/cache'
require 'benchmark'

# Setup cache stores
memory_store = ActiveSupport::Cache::MemoryStore.new
memcache_store = Pogocache::Cache.new

# Number of operations
N = 100_000

puts "Benchmarking WRITE performance (#{N} keys)..."
Benchmark.bm(20) do |x|
  x.report("MemoryStore write:") do
    N.times { |i| memory_store.write("key#{i}", "value#{i}") }
  end

  x.report("Memcached write:") do
    N.times { |i| memcache_store.set("key#{i}", "value#{i}") }
  end
end

puts "\nBenchmarking READ performance (#{N} keys)..."
Benchmark.bm(20) do |x|
  x.report("MemoryStore read:") do
    N.times { |i| memory_store.read("key#{i}") }
  end

  x.report("Memcached read:") do
    N.times { |i| memcache_store.get("key#{i}") }
  end
end
```

```
Benchmarking WRITE performance (100000 keys)...
                           user     system      total        real
MemoryStore write:     0.625948   0.020196   0.646144 (  0.646447)
Memcached write:       0.152022   0.003981   0.156003 (  0.156018)

Benchmarking READ performance (100000 keys)...
                           user     system      total        real
MemoryStore read:      0.389438   0.011676   0.401114 (  0.401121)
Memcached read:        0.113507   0.000096   0.113603 (  0.113615)
```
