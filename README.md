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

memory_store = ActiveSupport::Cache::MemoryStore.new
pogocache_store = Pogocache::Cache.new

N = 100_000

puts "Benchmarking WRITE performance (#{N} keys)..."
Benchmark.bm(20) do |x|
  x.report("MemoryStore write:") do
    N.times { |i| memory_store.write("key#{i}", "value#{i}") }
  end

  x.report("Pogocache write:") do
    N.times { |i| pogocache_store.set("key#{i}", "value#{i}") }
  end
end

puts "\nBenchmarking READ performance (#{N} keys)..."
Benchmark.bm(20) do |x|
  x.report("MemoryStore read:") do
    N.times { |i| memory_store.read("key#{i}") }
  end

  x.report("Pogocache read:") do
    N.times { |i| pogocache_store.get("key#{i}") }
  end
end
```

```
Benchmarking WRITE performance (100000 keys)...
                           user     system      total        real
MemoryStore write:     0.632989   0.019658   0.652647 (  0.652912)
Pogocache write:       0.147483   0.004175   0.151658 (  0.151699)

Benchmarking READ performance (100000 keys)...
                           user     system      total        real
MemoryStore read:      0.391422   0.000000   0.391422 (  0.391438)
Pogocache read:        0.112165   0.000000   0.112165 (  0.112170)
```
