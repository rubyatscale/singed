describe Kernel, "extension" do
  let(:flamegraph) { 
    instance_double(Singed::Flamegraph)
  }

  before do
    allow(Singed::Flamegraph).to receive(:new).and_return(flamegraph)
    allow(flamegraph).to receive(:record)
    allow(flamegraph).to receive(:save)
    allow(flamegraph).to receive(:open)
    allow(flamegraph).to receive(:open_command)
    allow(flamegraph).to receive(:filename)
  end

  let(:io) { StringIO.new }

  it "works without any arguments" do
    # * except what's needed to test
    # note: use Object.new to get the actual flamegraph kernel extension, instead of the rspec-specific flamegraph
    Object.new.flamegraph io: io do
    end

    expect(Singed::Flamegraph).to have_received(:new).with(label: nil, ignore_gc: false, interval: 1000)
  end

  it "works with explicit arguments" do
    # note: use Object.new to get the actual flamegraph kernel extension, instead of the rspec-specific flamegraph
    Object.new.flamegraph 'yellowjackets', ignore_gc: true, interval: 2000, io: io do
    end

    expect(Singed::Flamegraph).to have_received(:new).with(label: 'yellowjackets', ignore_gc: true, interval: 2000)
  end

  context "default" do
    it "opens" do
      Object.new.flamegraph open: true, io: io do
      end
      
      expect(flamegraph).to have_received(:open)
    end
  end

  context "open: true" do
    it "opens" do
      Object.new.flamegraph open: true, io: io do
      end

      expect(flamegraph).to have_received(:open)
    end
  end

  context "open: false" do
    it "doesn't open" do
      Object.new.flamegraph open: false, io: io do
      end

      expect(flamegraph).to_not have_received(:open)
    end
  end
end
