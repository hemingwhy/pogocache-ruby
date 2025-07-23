# frozen_string_literal: true

module Pogocache
  # Global configuration for pogocache
  class Configuration
    attr_accessor :library_path, :max_memory, :shard_count

    def initialize
      @library_path = nil
      @max_memory = nil
      @shard_count = 4096
    end
  end
end
