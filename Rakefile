# frozen_string_literal: true

require "bundler/gem_tasks"
require "open-uri"
require "fileutils"
require "tmpdir"
require "zip"
require_relative "lib/singed/speedscope"

namespace :speedscope do
  destination_dir = File.expand_path("vendor/speedscope", __dir__)

  desc "Download and unpack speedscope into vendor/speedscope"
  task vendor: destination_dir

  directory destination_dir do
    version = Singed::Speedscope::VERSION
    url = "https://github.com/jlfwong/speedscope/releases/download/v#{version}/speedscope-#{version}.zip"

    unzip_dir = File.expand_path("..", destination_dir) # speedscope dir is in the archive
    FileUtils.mkdir_p(destination_dir)

    tmp_zip = File.join(Dir.tmpdir, "speedscope-#{version}.zip")

    puts "Downloading speedscope from #{url}"
    URI.parse(url).open do |remote|
      File.open(tmp_zip, "wb") do |file|
        IO.copy_stream(remote, file)
      end
    end

    puts "Vendoring speedscope into #{unzip_dir}"
    Zip::File.open(tmp_zip) do |zip_file|
      zip_file.each do |entry|
        destination = File.join(unzip_dir, entry.name)
        if entry.directory?
          FileUtils.mkdir_p(destination)
        else
          FileUtils.mkdir_p(File.dirname(destination))
          entry.extract(destination_directory: unzip_dir)
        end
      end
    end
  end

  desc "Remove the unpacked speedscope directory"
  task :clobber do
    FileUtils.rm_rf(destination_dir)
  end
end

Rake::Task[:build].enhance ["speedscope:vendor"]
Rake::Task[:clobber].enhance ["speedscope:clobber"]

task default: %i[]
