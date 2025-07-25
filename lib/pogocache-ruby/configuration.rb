# frozen_string_literal: true

module Pogocache
  # Global configuration for pogocache
  class Configuration
    attr_accessor :shard_count, :buffer_size

    def initialize
      @buffer_size = 1024 * 4096
      @shard_count = 4096
    end
  end
end
