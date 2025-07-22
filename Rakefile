# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "standard/rake"
require "yard"
require "rake/extensiontask"

RSpec::Core::RakeTask.new(:spec)
YARD::Rake::YardocTask.new

task default: %i[spec standard]

Rake::ExtensionTask.new "pogocache" do |ext|
  ext.lib_dir = "ext/pogocache"
end

# Custom tasks for building pogocache library
namespace :pogocache do
  desc "Download and build pogocache library"
  task :build_lib do
    require_relative "lib/pogocache/platform"

    ext_dir = File.join(__dir__, "ext", "pogocache")
    FileUtils.mkdir_p(ext_dir)

    Dir.chdir(ext_dir) do
      unless File.exist?("pogocache.c")
        puts "Downloading pogocache source..."
        system("curl -L https://raw.githubusercontent.com/tidwall/pogocache/refs/heads/main/src/pogocache.c -o pogocache.c")
        system("curl -L https://raw.githubusercontent.com/tidwall/pogocache/refs/heads/main/src/pogocache.h -o pogocache.h")
      end

      puts "Building pogocache library..."
      lib_name = Pogocache::Platform.library_name
      build_cmd = "make"
      system(build_cmd) or raise "Failed to build pogocache library"
      puts "Successfully built #{lib_name}"
    end
  end
end

desc "Clean built libraries"
task :clean do
  ext_dir = File.join(__dir__, "ext", "pogocache")
  FileUtils.rm_f(Dir[File.join(ext_dir, "*.{so,dylib,o}")])
end

# Build library before running tests
task spec: "compile"
