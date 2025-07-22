# frozen_string_literal: true

require_relative "lib/pogocache/version"

Gem::Specification.new do |spec|
  spec.name = "pogocache-ruby"
  spec.version = Pogocache::VERSION
  spec.authors = ["heming"]
  spec.email = ["git@heming.dev"]

  spec.summary = "Bindings for pogocache"
  spec.description = "Bindings for pogocache"
  spec.homepage = "https://github.com/hemingwhy/pogocache-ruby"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["allowed_push_host"] = nil
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/change"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore .rspec spec/ .github/ .standard.yml])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"
  # Runtime dependencies
  spec.add_runtime_dependency "ffi", "~> 1.15"

  # Development dependencies
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.12"
  spec.add_development_dependency "rubocop", "~> 1.50"
  spec.add_development_dependency "rubocop-rspec", "~> 2.20"
  spec.add_development_dependency "yard", "~> 0.9"
  spec.add_development_dependency "simplecov", "~> 0.22"

  # Platform restrictions (pogocache only supports 64-bit Linux and macOS)
  spec.platform = Gem::Platform::RUBY

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
