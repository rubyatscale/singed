# frozen_string_literal: true

describe Singed::RackMiddleware do
  subject do
    instance.call(env)
  end

  let(:app_response) { [200, {"content-type" => "text/plain"}, ["OK"]] }
  let(:app) { ->(*) { app_response } }
  let(:instance) { described_class.new(app) }
  let(:env) { Rack::MockRequest.env_for("/", headers) }
  let(:headers) { {} }

  it "returns a proper rack response" do
    linted_app = Rack::Lint.new(instance)
    expect { linted_app.call(env) }.not_to raise_error
  end

  it "passes through the app response unchanged" do
    expect(subject).to eq(app_response)
  end

  context "when enabled" do
    before do
      allow_any_instance_of(Singed::Flamegraph).to receive(:open)
      allow(instance).to receive(:capture_flamegraph?).and_return(true)
    end

    it "captures a flamegraph" do
      expect(instance).to receive(:flamegraph).and_call_original
      subject
    end

    it "returns a proper rack response" do
      linted_app = Rack::Lint.new(instance)
      expect { linted_app.call(env) }.not_to raise_error
    end

    it "passes through the app response unchanged" do
      expect(subject).to eq(app_response)
    end
  end

  describe "#capture_flamegraph?" do
    subject { instance.capture_flamegraph?(env) }

    it { is_expected.to be false }

    context "when HTTP_X_SINGED is true" do
      let(:headers) { {"HTTP_X_SINGED" => "true"} }

      it { is_expected.to be true }
    end

    context "when SINGED_MIDDLEWARE_ALWAYS_CAPTURE env var is set" do
      around do |example|
        original = ENV["SINGED_MIDDLEWARE_ALWAYS_CAPTURE"]
        described_class.remove_instance_variable(:@always_capture) if described_class.instance_variable_defined?(:@always_capture)
        example.run
      ensure
        if original.nil?
          ENV.delete("SINGED_MIDDLEWARE_ALWAYS_CAPTURE")
        else
          ENV["SINGED_MIDDLEWARE_ALWAYS_CAPTURE"] = original
        end
        described_class.remove_instance_variable(:@always_capture) if described_class.instance_variable_defined?(:@always_capture)
      end

      %w[true 1 yes].each do |truthy_value|
        context "when SINGED_MIDDLEWARE_ALWAYS_CAPTURE=#{truthy_value}" do
          before { ENV["SINGED_MIDDLEWARE_ALWAYS_CAPTURE"] = truthy_value }

          it { is_expected.to be true }
        end
      end

      context "when SINGED_MIDDLEWARE_ALWAYS_CAPTURE=false" do
        before { ENV["SINGED_MIDDLEWARE_ALWAYS_CAPTURE"] = "false" }

        it { is_expected.to be false }
      end
    end
  end
end
