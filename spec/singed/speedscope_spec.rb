# frozen_string_literal: true

require "tempfile"

RSpec.describe Singed::Speedscope do
  describe ".open" do
    let(:profile_path) do
      Tempfile.new(["profile", ".json"]).tap do |file|
        file.write("{}")
        file.flush
      end.path
    end

    context "when bundled speedscope exists" do
      before do
        allow(File).to receive(:exist?).with(described_class.bundled_index_html).and_return(true)
      end

      it "opens with bundled speedscope" do
        allow(described_class).to receive(:system).and_return(true)

        described_class.open(profile_path)

        expect(described_class).to have_received(:system).with(described_class.send(:os_open_command), %r{\Afile://})
      end
    end

    context "when bundled speedscope does not exist" do
      before do
        allow(File).to receive(:exist?).with(described_class.bundled_index_html).and_return(false)
      end

      it "opens with npx speedscope" do
        allow(described_class).to receive(:system).and_return(true)

        described_class.open(profile_path)

        expect(described_class).to have_received(:system).with("npx", "speedscope", profile_path)
      end
    end
  end

  describe ".os_open_command" do
    it "returns a command and does not raise" do
      expect { described_class.send(:os_open_command) }.not_to raise_error
      expect(described_class.send(:os_open_command)).to match(/\A(start|open|xdg-open)\z/)
    end

    context "when host_os is stubbed" do
      subject { described_class.send(:os_open_command) }

      before do
        allow(RbConfig::CONFIG).to receive(:[]).with("host_os").and_return(stubbed_os)
      end

      context "on Windows" do
        let(:stubbed_os) { "mingw32" }

        it { is_expected.to eq("start") }
      end

      context "on MacOS" do
        let(:stubbed_os) { "darwin22.0" }

        it { is_expected.to eq("open") }
      end

      context "on Linux" do
        let(:stubbed_os) { "linux-gnu" }

        it { is_expected.to eq("xdg-open") }
      end

      context "on unsupported OS" do
        let(:stubbed_os) { "unknown-os" }

        it "raises error" do
          expect { subject }.to raise_error(RuntimeError, /unknown-os/)
        end
      end
    end
  end
end
