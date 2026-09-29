# typed: strict
# frozen_string_literal: true

require "shellwords"
require "tmpdir"
require "optionparser"

# NOTE: we defer requiring singed until we run. that lets Rails load it if its in the gemfile, so the railtie has had a chance to run

module Singed
  class CLI
    #: Array[String]
    attr_accessor :argv

    #: Pathname?
    attr_accessor :filename

    #: OptionParser
    attr_accessor :opts

    #: (Array[String]) -> void
    def initialize(argv)
      @argv = argv
      @opts = OptionParser.new #: OptionParser

      parse_argv!
    end

    #: () -> void
    def parse_argv!
      opts.banner = "Usage: singed [options] <command>"

      opts.on("-h", "--help", "Show this message") do
        @show_help = true #: bool?
      end

      opts.on("-o", "--output-directory DIRECTORY", "Directory to write flamegraph to") do |directory|
        @output_directory = directory #: String?
      end

      opts.on("-r", "--rate RATE", Integer, "Sample rate for rbspy") do |rate|
        @rate = rate #: Integer?
      end

      opts.order(@argv) do |arg|
        opts.terminate if arg == "--"
        break
      end

      if @argv.empty?
        @show_help = true
        @error_message = "missing command to profile" #: (String | OptionParser::InvalidOption)?
        return
      end

      return if @show_help

      begin
        @opts.parse!(argv)
      rescue OptionParser::InvalidOption => e
        @show_help = true
        @error_message = e
      end
    end

    #: () -> void
    def run
      require "singed"

      if @error_message
        puts @error_message
        puts
        puts @opts.help
        exit 1
      end

      if show_help?
        puts @opts.help
        exit 0
      end

      Singed.output_directory = @output_directory if @output_directory
      Singed.output_directory ||= Dir.tmpdir
      # The ||= above has just set output_directory if it was unset.
      FileUtils.mkdir_p(
        Singed.output_directory #: as !nil
      )
      @filename = Singed::Flamegraph.generate_filename(label: "cli")

      options = {
        format: "speedscope",
        file: filename.to_s,
        rate: @rate,
        silent: nil,
      }

      rbspy_args = [
        "record",
        *options.map { |k, v| ["--#{k}", v].compact }.flatten,
        "--",
        *argv,
      ]

      loop do
        break unless password_needed?

        puts "🔥📈 Singed needs to run as root, but will drop permissions back to your user. Prompting with sudo now..."
        prompt_password
      end

      rbspy = -> do
        # don't run things with spring, because it forks and rbspy won't see it
        sudo ["rbspy", *rbspy_args], reason: "Singed needs to run as root, but will drop permissions back to your user.", env: { "DISABLE_SPRING" => "1" }
      end

      if defined?(Bundler)
        Bundler.with_unbundled_env do
          rbspy.call
        end
      else
        rbspy.call
      end

      # @filename rather than the nilable filename reader: Sorbet knows it holds a Pathname by now.
      unless @filename.exist?
        puts "#{filename} doesn't exist. Maybe rbspy had a failure capturing it? Check the scrollback."
        exit 1
      end

      unless adjust_ownership!
        puts "#{filename} isn't writable!"
        exit 1
      end

      # clean the report, similar to how Singed::Report does
      json = JSON.parse(@filename.read)
      json["shared"]["frames"].each do |frame|
        frame["file"] = Singed.filter_line(frame["file"])
      end
      @filename.write(JSON.dump(json))

      flamegraph = Singed::Flamegraph.new(filename:)
      flamegraph.open
    end

    #: () -> bool
    def password_needed?
      !system("sudo --non-interactive true >/dev/null 2>&1")
    end

    #: () -> bool?
    def prompt_password
      system("sudo true")
    end

    #: () -> bool
    def adjust_ownership!
      sudo ["chown", ENV["USER"], filename], reason: "Adjusting ownership of #{filename}, but need root."
    end

    #: () -> bool?
    def show_help?
      @show_help
    end

    # Never nil or false: exception: true makes Kernel#system raise instead.
    #: (Array[String | Integer | Pathname | nil], reason: String, ?env: Hash[String, String]) -> bool
    def sudo(system_args, reason:, env: {})
      loop do
        break unless password_needed?

        puts "🔥📈 #{reason} Prompting with sudo now..."
        prompt_password
      end

      sudo_args = [
        "sudo",
        "--preserve-env",
        *system_args.map(&:to_s),
      ]

      puts "$ #{Shellwords.join(sudo_args)}"

      # Sorbet can't check a splat of an array of unknown length: https://srb.help/7019
      #: self as untyped
      system(env, *sudo_args, exception: true)
    end

    #: () -> String?
    def self.chdir_rails_root
      original_cwd = Dir.pwd

      loop do
        if File.file?("config/environment.rb")
          return Dir.pwd
        end

        if Pathname.new(Dir.pwd).root?
          Dir.chdir(original_cwd)
          return
        end

        # Otherwise keep moving upwards in search of an executable.
        Dir.chdir("..")
      end
    end
  end
end
