require "pogocache-ruby"
require "active_support"
require "active_support/cache"
require "benchmark"
require "benchmark/memory"

memory_store = ActiveSupport::Cache::MemoryStore.new
pogocache_store = Pogocache::Cache.new

N = 100_000

puts "Benchmarking WRITE performance (#{N} keys)..."
Benchmark.bm(20) do |x|
  x.report("MemoryStore write:") do
    N.times { |i| memory_store.write(i, i) }
  end

  x.report("Pogocache write:") do
    N.times { |i| pogocache_store.set(i, i) }
  end
end

puts "\nBenchmarking READ performance (#{N} keys)..."
Benchmark.bm(20) do |x|
  x.report("MemoryStore read:") do
    N.times { |i| memory_store.read(i) }
  end

  x.report("Pogocache read:") do
    N.times { |i| pogocache_store.get(i) }
  end
end

puts "\nBenchmarking memory performance (#{N} keys)..."
Benchmark.memory do |x|
  x.report("MemoryStore:") do
    N.times { |i| memory_store.write(i, i) }
    N.times { |i| memory_store.read(i) }
  end

  x.report("Pogocache:") do
    N.times { |i| pogocache_store.set(i, i) }
    N.times { |i| pogocache_store.get(i) }
  end
end
