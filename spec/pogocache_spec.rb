# frozen_string_literal: true

RSpec.describe Pogocache do
  it "has a version number" do
    expect(Pogocache::VERSION).not_to be_nil
  end

  describe ".new" do
    it "creates a new cache instance" do
      cache = described_class.new
      expect(cache).to be_a(Pogocache::Cache)
      cache.close
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
      cache.set("test", :value, ttl: 1)
      expect(cache.get("test")).not_to be_nil
      sleep 2 / 10e3
      expect(cache.get("test")).to be_nil
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

  describe "now" do
    it "works" do
      expect(described_class.now).not_to be_nil
    end
  end

  it "counts" do
    cache = described_class.new
    cache.set("a", "a value")
    cache.set("b", "another value")
    cache.set("c", "a third value")
    expect(cache.count).to eq(3)
    puts cache.size
    puts cache.total
  end

end
