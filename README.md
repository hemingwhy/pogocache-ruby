# Pogocache::Ruby

Use [pogocache](https://github.com/tidwall/pogocache) as an in-memory store in Ruby.
This gem embeds pogocache as a C extension and uses a fixed buffer for performant operations.
The goal is to provide a lightweight alternative to `ActiveSupport::Cache::MemoryStore`.
The state of this project is pretty much pre alfa but functional.

## Features

- Fast caching operations
- Low memory footprint
- Arbitrary objects as keys and values
- Linux and MacOS support
- `Enumerable` interface

## Threading

This gem relies on the GVL when used in a multi-threaded context.
It does not free the lock before any operation.

## Usage

```
  [...]
```

*This gem uses a buffer of 4MB to read from the cache.*
*If your values are bigger, it might crash.*

## Todos

- [ ] gem configuration: default cache opts, buffer size(s),...
- [ ] configurable buffer size per cache
- [ ] option to allocate a buffer for each read
- [ ] collect batch operation results
- [ ] add interface to be used as a rails cache
- [ ] implement all operation options

## Benchmark

```ruby
require 'pogocache-ruby'
require 'active_support'
require 'active_support/cache'
require 'benchmark'
require 'benchmark/memory'

memory_store = ActiveSupport::Cache::MemoryStore.new
pogocache_store = Pogocache::Cache.new(usecas: true, nosixpack: true)
pogocache_batch_store = Pogocache::Cache.new

N = 100_000

puts "Benchmarking WRITE performance (#{N} keys)..."
Benchmark.bm(20) do |x|
  x.report("MemoryStore write:") do
    N.times { |i| memory_store.write("key#{i}", { number: i, value: nil}) }
  end

  x.report("Pogocache write:") do
    N.times { |i| pogocache_store.set("key#{i}", { number: i, value: nil}) }
  end
  
    x.report("Pogocache batch write:") do
    pogocache_batch_store.batch { |b| N.times { |i| b.set("key#{i}", { number: i, value: nil}) } }
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

  x.report("Pogocache batch read:") do
    pogocache_batch_store.batch { |b| N.times { |i| b.get("key#{i}") } }
  end
end

Benchmark.memory do |x|
  x.report("MemoryStore write:") do
    N.times { |i| memory_store.write("key#{i}", { number: i, value: nil}) }
  end

  x.report("Pogocache write:") do
    N.times { |i| pogocache_store.set("key#{i}", { number: i, value: nil}) }
  end
  
  x.report("Pogocache batch write:") do
    pogocache_batch_store.batch { |b| N.times { |i| b.set("key#{i}", { number: i, value: nil}) } }
  end
end

puts "\nBenchmarking READ performance (#{N} keys)..."
Benchmark.memory do |x|
  x.report("MemoryStore read:") do
    N.times { |i| memory_store.read("key#{i}") }
  end

  x.report("Pogocache read:") do
    N.times { |i| pogocache_store.get("key#{i}") }
  end

  x.report("Pogocache batch read:") do
    pogocache_batch_store.batch { |b| N.times { |i| b.get("key#{i}") } }
  end
end

```

```
Benchmarking WRITE performance (100000 keys)...
                            user     system      total        real
MemoryStore write:      0.705818   0.039556   0.745374 (  0.745811)
Pogocache write:        0.245812   0.008221   0.254033 (  0.254095)
Pogocache batch write:  0.203316   0.003933   0.207249 (  0.207264)

Benchmarking READ performance (100000 keys)...
                           user     system      total        real
MemoryStore read:      0.472150   0.012015   0.484165 (  0.484260)
Pogocache read:        0.231064   0.000000   0.231064 (  0.231067)
Pogocache batch read:  0.228220   0.000000   0.228220 (  0.228236)
Calculating -------------------------------------
  MemoryStore write:   239.200M memsize (    15.200M retained)
                         2.000M objects (   200.000k retained)
                        50.000  strings (    50.000  retained)
    Pogocache write:    38.396M memsize (   160.000  retained)
                       499.990k objects (     1.000  retained)
                        50.000  strings (     0.000  retained)
Pogocache batch write:
                        38.397M memsize (   160.000  retained)
                       499.992k objects (     1.000  retained)
                        50.000  strings (     0.000  retained)

Benchmarking READ performance (100000 keys)...
Calculating -------------------------------------
   MemoryStore read:   116.000M memsize (     0.000  retained)
                         1.200M objects (     0.000  retained)
                        50.000  strings (     0.000  retained)
     Pogocache read:    55.996M memsize (     0.000  retained)
                       799.990k objects (     0.000  retained)
                        50.000  strings (     0.000  retained)
Pogocache batch read:
                        55.997M memsize (     0.000  retained)
                       799.992k objects (     0.000  retained)
                        50.000  strings (     0.000  retained)

```
