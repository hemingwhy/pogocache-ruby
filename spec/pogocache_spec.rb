# frozen_string_literal: true

RSpec.describe Pogocache::Cache do
  it "has a version number" do
    expect(Pogocache::VERSION).not_to be_nil
  end

  describe ".new" do
    it "creates a new cache instance" do
      cache = described_class.new
      expect(cache).to be_a(Pogocache::Cache)
    end
  end

  describe "set" do
    it "lets you save a string value" do
      cache = described_class.new
      cache.set("name", "Adam")
      expect(cache.get("name")).to eq("Adam")
    end

    it "lets you save a object value" do
      cache = described_class.new
      cache.set("address", {street: "Abby Road 2", city: "London"})
      expect(cache.get("address")).to eq({street: "Abby Road 2", city: "London"})
    end

    it "stores arrays" do
      cache = described_class.new
      cache.set("array", [1, 2, 3, 4])
      expect(cache.get("array")).to eq([1, 2, 3, 4])
      cache.set("empty", [])
      expect(cache.get("empty")).to eq([])
      cache.set("big", Array.new(10_000))
      expect(cache.get("big")).to eq(Array.new(10_000))
    end

    it "works with objects as keys" do
      cache = described_class.new
      cache.set([], "empty array")
      expect(cache.get([])).to eq("empty array")
    end

    it "lets you save multiple values" do
      cache = described_class.new
      cache.set("name", "Ada")
      cache.set("last_name", "Lovelace")

      expect(cache["name"]).to eq("Ada")
      expect(cache["last_name"]).to eq("Lovelace")
    end

    it "allows multiple caches in parallel" do
      cache1 = described_class.new
      cache1.set("name", "Ada")
      cache1.set("last_name", "Lovelace")

      cache2 = described_class.new
      cache2.set("name", "Adam")
      cache2.set("last_name", "Turing")

      expect(cache1["name"]).to eq("Ada")
      expect(cache1["last_name"]).to eq("Lovelace")

      expect(cache2["name"]).to eq("Adam")
      expect(cache2["last_name"]).to eq("Turing")
    end

    it "ttl works" do
      cache = described_class.new
      cache.set("test", :value, ttl: 300_000)
      cache.set("test6", :value, ttl: nil)
      cache.set("test5", :value, ttl: nil)
      cache.set("test2", :value, ttl: 1)
      cache.set("test3", :value, ttl: 1)
      cache.set("test4", :value, ttl: 1)
      expect(cache.get("test")).not_to be_nil
      sleep 4 / 10e3
      expect(cache.get("test")).to be_nil
      expect(cache.sweep).to eq(swept: 3, kept: 2)
    end
  end

  describe "delete operation" do
    it "works" do
      cache = described_class.new
      cache.set("tobedeleted", "nothing")
      cache.set("nottobedeleted", "something")
      expect(cache.get("tobedeleted")).to eq("nothing")
      expect { cache.delete("tobedeleted") }.not_to raise_error
      expect(cache.get("tobedeleted")).to be_nil
      expect(cache.get("nottobedeleted")).to eq("something")
    end
  end

  it "counts" do
    cache = described_class.new
    cache.set("a", "a value")
    expect(cache.count).to eq(1)
    cache.set("b", "another value")
    cache.set("c", "a third value")
    expect(cache.count).to eq(3)
    cache.delete("a")
    cache.set("d", "another third value")
    expect(cache.count).to eq(3)
    expect(cache.bytesize).to be_positive
  end

  describe "enumerator" do
    it "works" do
      cache = described_class.new
      cache.set("a", "a value")
      cache.set("b", "another value")
      cache.set("c", "a third value")
      cache.set("d", "another third value")
      expect(cache.each { |k, _v| k }).to match_array(%w[a b c d]) # standard:disable Lint/Void
      cache.clear
      expect(cache.count).to eq(0)
      expect(cache.each).to be_empty
    end
  end

  describe "multi threading" do
    it "does not raise an error" do
      threads = []
      2.times do
        threads << Thread.new do
          cache = described_class.new
          100.times {
            cache.set("thread_test", 212)
            cache.get("thread_test")
          }
        end
      end

      threads.each(&:join)
      expect(true).to eq(true)
    end
  end

  describe "hash interface" do
    it "works with [] and []=" do
      cache = described_class.new
      cache[{}] = {test: :test}
      expect(cache[{}]).to eq({test: :test})
    end

    it "works with fetch" do
      cache = described_class.new
      cache[:test] = :test
      expect(cache.fetch(:empty) { :fallback }).to eq(:fallback)
      expect(cache.fetch(:test) { :fallback }).to eq(:test)
    end
  end

  describe ".entry" do
    it "has all the keys" do
      cache = described_class.new
      cache[:test] = {an: :entry}
      entry = cache.entry(:test)
      expect(entry.keys).to match_array(%i[cas expires flags key shard time value])
    end
  end

  describe "configuration" do
    it "works" do
      Pogocache.configure do
        it.default_opts = {nshards: 1010}
      end

      cache = described_class.new
      expect(cache.nshards).to eq(1010)
    end
  end
end
