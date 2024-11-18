describe Singed::RackMiddleware do
  subject do
    instance.call(env)
  end

  let(:app) { ->(*) { [200, {'Content-Type' => 'text/plain'}, ['OK']] } }
  let(:instance) { described_class.new(app) }
  let(:env) { Rack::MockRequest.env_for('/', headers) }
  let(:headers) { {} }

  it 'returns a proper rack response' do
    status, _ = subject
    expect(status).to eq 200
  end

  it 'does not capture a flamegraph by default' do
    expect(instance).not_to receive(:flamegraph)
    subject
  end

  context 'when enabled' do
    before { allow(instance).to receive(:capture_flamegraph?).and_return(true) }

    it 'captures a flamegraph' do
      expect(instance).to receive(:flamegraph)
      subject
    end
  end

  describe '.capture_flamegraph?' do
    subject { instance.capture_flamegraph?(env) }

    it { is_expected.to be false }

    context 'when HTTP_X_SINGED is true' do
      let(:headers) { { 'HTTP_X_SINGED' => 'true' } }

      it { is_expected.to be true }
    end
  end
end
