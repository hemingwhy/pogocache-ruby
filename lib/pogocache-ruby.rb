# frozen_string_literal: true

require_relative "pogocache_ruby"
require_relative "pogocache-ruby/version"
require_relative "pogocache-ruby/configuration"
require_relative "pogocache-ruby/cache"

module Pogocache
  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end
  end
end
