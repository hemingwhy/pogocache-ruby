# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in pogocache.gemspec
gemspec

# Additional development dependencies
group :development do
  gem "debug", "~> 1.11"
  gem "pry"
  gem "pry-byebug"
  gem "guard"
  gem "guard-rspec"
  gem "ruby-lsp"
end

# Platform-specific gems
platforms :ruby do
  gem "rake-compiler", "~> 1.2"
end
