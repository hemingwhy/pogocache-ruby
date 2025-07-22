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
      expect(cache.get("name")&.value).to eq("Adam")
    end
    it "lets you save a object value" do
      cache = described_class.new
      cache.set("address", { street: "Abby Road 2", city: "London"})
      expect(cache.get("address")&.value).to eq({ street: "Abby Road 2", city: "London"})
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
  end
end
