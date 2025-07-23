# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "standard/rake"
require "yard"
require "rake/extensiontask"

RSpec::Core::RakeTask.new(:spec)
YARD::Rake::YardocTask.new

task default: %i[spec standard]

Rake::ExtensionTask.new "pogocache"

namespace :pogocache do
  desc "Download pogocache library"
  task :build_lib do
    require_relative "lib/pogocache/platform"

    ext_dir = File.join(__dir__, "ext", "pogocache")
    FileUtils.mkdir_p(ext_dir)

    Dir.chdir(ext_dir) do
      puts "Downloading pogocache source..."
      system("curl -L https://raw.githubusercontent.com/tidwall/pogocache/refs/heads/main/src/pogocache.c -o pogocache.c")
      system("curl -L https://raw.githubusercontent.com/tidwall/pogocache/refs/heads/main/src/pogocache.h -o pogocache.h")
    end
  end
end

# Build library before running tests
task spec: "compile"
