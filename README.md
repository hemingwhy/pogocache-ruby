# Pogocache::Ruby

Use [pogocache](https://github.com/tidwall/pogocache) as an in-memory store in Ruby.
This gem embeds pogocache as a C extension and provides the class `Pogocache::Cache`to interact with it.
The goal is to provide a faster, more lightweight alternative to `ActiveSupport::Cache::MemoryStore.
The state of this project is pretty much pre alfa but functional.

## Features

- Fast caching operations
- Low memory footprint
- Arbitrary objects as keys and values
- Linux and MacOS support

## Threading

This gem relies on the GVL when used in a multi-threaded context.
It does not free the lock before any operation.

## Usage

```
  [...]
```

## Todos

- [ ] add interface to be used as a rails cache
- [ ] improve interface

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

puts "Benchmarking WRITE performance (#{N} keys)..."
Benchmark.memory do |x|
  x.report("MemoryStore write:") do
    N.times { |i| memory_store.write("key#{i}", { number: i, value: nil}) }
  end

  x.report("Pogocache write:") do
    N.times { |i| pogocache_store.set("key#{i}", { number: i, value: nil}) }
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
end

```

```
Benchmarking WRITE performance (100000 keys)...
                           user     system      total        real
MemoryStore write:     0.663600   0.015039   0.678639 (  0.678977)
Pogocache write:       0.193228   0.012096   0.205324 (  0.205405)

Benchmarking READ performance (100000 keys)...
                           user     system      total        real
MemoryStore read:      0.456161   0.003899   0.460060 (  0.460138)
Pogocache read:        0.205501   0.000000   0.205501 (  0.205520)

Benchmarking WRITE performance (100000 keys)...
Calculating -------------------------------------
  MemoryStore write:   239.200M memsize (    15.200M retained)
                         2.000M objects (   200.000k retained)
                        50.000  strings (    50.000  retained)
    Pogocache write:    54.396M memsize (     0.000  retained)
                       599.990k objects (     0.000  retained)
                        50.000  strings (     0.000  retained)

Benchmarking READ performance (100000 keys)...
Calculating -------------------------------------
   MemoryStore read:   116.000M memsize (     0.000  retained)
                         1.200M objects (     0.000  retained)
                        50.000  strings (     0.000  retained)
     Pogocache read:    71.192M memsize (     0.000  retained)
                       899.990k objects (     0.000  retained)
                        50.000  strings (     0.000  retained)

```
