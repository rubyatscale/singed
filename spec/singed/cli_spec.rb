# typed: false
# frozen_string_literal: true

require "rbconfig"
require "singed/cli"

# Runs exe/singed with stand-ins for sudo, for rbspy, and for the commands that open flamegraphs.
RSpec.describe Singed::CLI do
  let(:dir) { Pathname(Dir.mktmpdir("singed-cli-spec")) }
  let(:bin) { dir.join("bin").tap(&:mkpath) }
  let(:interrupts) { dir.join("interrupts.log") } # a line for each SIGINT rbspy gets
  let(:opened) { dir.join("opened.log") }
  let(:output) { dir.join("output.log") }
  let(:rbspy_args) { dir.join("rbspy_args.json") }
  let(:rbspy_exit_status) { nil } # for rbspy to fail with, straight away
  let(:started) { dir.join("started") } # the profiled command's pid, once it runs

  # Writes the stand-ins first, so no path through the hooks runs singed with the real sudo. It runs as
  # `bundle exec singed` would, but without this process's Bundler environment, whose BUNDLER_ORIG_PATH
  # would have singed's Bundler.with_unbundled_env take the stand-ins back off PATH. And it runs in its
  # own process group, so the after hook can clean up whatever singed leaves running.
  let!(:singed) do
    write_stand_ins
    Bundler.with_unbundled_env do
      Process.spawn(
        {
          "PATH" => "#{bin}:#{ENV.fetch('PATH')}",
          "BUNDLE_GEMFILE" => File.expand_path("../../Gemfile", __dir__),
          "RUBYOPT" => "-rbundler/setup",
        },
        RbConfig.ruby, File.expand_path("../../exe/singed", __dir__), "--output-directory", dir.to_s,
        "--", RbConfig.ruby, "-e", "File.write(ARGV[0], Process.pid.to_s); sleep", started.to_s,
        chdir: dir.to_s, out: output.to_s, err: output.to_s, pgroup: true
      )
    end
  end

  after do
    Process.kill("KILL", -singed)
  rescue Errno::ESRCH, Errno::EPERM
    # Everything has exited. macOS says EPERM when only an unreaped singed is left.
  ensure
    FileUtils.rm_rf(dir)
  end

  def write_stand_ins
    write_executable "sudo", <<~SH
      #!/bin/sh
      while [ "${1#-}" != "$1" ]; do shift; done
      exec "$@"
    SH
    # Like rbspy, stops at the first SIGINT, then takes a moment to write the flamegraph, and exits
    # without writing anything at a second SIGINT.
    write_executable "rbspy", <<~RUBY
      #!#{RbConfig.ruby}
      #{"exit #{rbspy_exit_status}" if rbspy_exit_status}
      require "json"
      File.write(#{rbspy_args.to_s.inspect}, JSON.generate(ARGV))
      file = ARGV[ARGV.index("--file") + 1]
      command = Process.spawn(*ARGV.drop(ARGV.index("--") + 1))
      trap("INT") do
        File.write(#{interrupts.to_s.inspect}, "INT\\n", mode: "a")
        exit!(1) if $interrupted
        $interrupted = true
        Process.kill("KILL", command)
      end
      Process.wait(command)
      sleep 0.5 if $interrupted
      File.write(file, JSON.generate(shared: { frames: [{ name: "<main>", file: "script.rb" }] }, profiles: []))
    RUBY
    ["npx", "open", "xdg-open"].each do |opener|
      write_executable opener, <<~SH
        #!/bin/sh
        echo "$0 $*" >> #{opened}
      SH
    end
  end

  def write_executable(name, script)
    bin.join(name).write(script)
    bin.join(name).chmod(0o755)
  end

  def eventually(timeout: 15)
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + timeout
    until (result = yield)
      raise "Timed out. singed's output:\n#{output.read}" if Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline

      sleep 0.02
    end
    result
  end

  def exit_status
    eventually { Process.wait2(singed, Process::WNOHANG)&.last }
  end

  it "stops rbspy and the profiled command when terminated, then opens the flamegraph" do
    command = eventually { started.exist? && started.read.to_i.nonzero? }
    Process.kill("TERM", singed)

    expect(exit_status).to be_success, output.read
    expect(interrupts.read).to eq("INT\n")
    expect(JSON.parse(rbspy_args.read)).to start_with("record", "--format", "speedscope", "--file", a_string_ending_with(".json"), "--silent", "--")
    expect { Process.kill(0, command) }.to raise_error(Errno::ESRCH)
    expect(dir.glob("speedscope-cli-*.json")).not_to be_empty
    expect(opened.read).not_to be_empty
  end

  it "passes on only the first SIGTERM, so rbspy can finish writing the flamegraph" do
    eventually { started.exist? }
    Process.kill("TERM", singed)
    eventually { interrupts.exist? }
    Process.kill("TERM", singed)

    expect(exit_status).to be_success, output.read
    expect(interrupts.read).to eq("INT\n")
    expect(dir.glob("speedscope-cli-*.json")).not_to be_empty
  end

  it "leaves Ctrl-C's SIGINT to reach rbspy from the terminal" do
    eventually { started.exist? }
    Process.kill("INT", singed)
    sleep 0.5

    expect(Process.wait2(singed, Process::WNOHANG)).to be_nil
    expect(interrupts).not_to exist

    Process.kill("TERM", singed)

    expect(exit_status).to be_success, output.read
    expect(interrupts.read).to eq("INT\n")
  end

  context "when rbspy fails" do
    let(:rbspy_exit_status) { 3 }

    it "fails too" do
      expect(exit_status).not_to be_success
      expect(output.read).to match(/rbspy record .* failed \(pid \d+ exit 3\)/)
    end
  end
end
