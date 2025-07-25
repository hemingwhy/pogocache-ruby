# frozen_string_literal: true

module Pogocache
  # Global configuration for pogocache
  class Configuration
    attr_accessor :default_opts

    def initialize
      @default_opts = {}
    end
  end
end
