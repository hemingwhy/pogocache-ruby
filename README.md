# Pogocache::Ruby

Use [pogocache](https://github.com/tidwall/pogocache) as an in-memory store in Ruby.
This gem embeds pogocache as a C extension and provides the class `Pogocache::Cache`to interact with it.
The goal is to provide a faster, more lightweight alternative to `ActiveSupport::Cache::MemoryStore.
The state of this project is pre release but functional. Feedback is welcome.

## Features

- Fast caching operations
- Low memory footprint
- Arbitrary objects as keys and values
- Linux and MacOS support

## Threading

This gem relies on the GVL when used in a multi-threaded context.
It does not free the lock before any operation.

## Usage

```sh
bundle add pogocache-ruby
```
```ruby
require 'pogocache-ruby'

cache = Pogocache::Cache.new

cache.set("value1", "string 1")
cache[:value2] = { hash_key: "value" }

cache.fetch(:value2)
# => {hash_key: "value"}
cache["value1"]
# => "string 1"
```

See [./spec/pogocache_spec.rb] and [./ext/pogocache_ruby/pogocache.h] for details.

## Benchmark

[./benchmark.rb]

```
Benchmarking WRITE performance (100000 keys)...
                           user     system      total        real
MemoryStore write:     0.526285   0.020191   0.546476 (  0.546561)
Pogocache write:       0.087404   0.003957   0.091361 (  0.091385)

Benchmarking READ performance (100000 keys)...
                           user     system      total        real
MemoryStore read:      0.302697   0.004301   0.306998 (  0.307099)
Pogocache read:        0.104694   0.000000   0.104694 (  0.104700)

Benchmarking memory performance (100000 keys)...
Calculating -------------------------------------
        MemoryStore:   232.000M memsize (     8.000M retained)
                         2.200M objects (   100.000k retained)
                        50.000  strings (     0.000  retained)
          Pogocache:    52.000M memsize (     0.000  retained)
                       700.000k objects (     0.000  retained)
                        50.000  strings (     0.000  retained)

```
