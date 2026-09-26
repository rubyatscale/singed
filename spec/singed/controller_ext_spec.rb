# frozen_string_literal: true

require "singed/controller_ext"

RSpec.describe Singed::ControllerExt do
  let(:controller_class) do
    Class.new do
      def self.around_action(**options, &block)
        around_actions << [options, block]
      end

      def self.around_actions
        @around_actions ||= []
      end

      include Singed::ControllerExt
    end
  end

  # Kernel#flamegraph makes every object respond to :flamegraph, so check where the method comes from.
  it "adds the flamegraph class method when included" do
    expect(controller_class.method(:flamegraph).owner).to eq(Singed::ControllerExt::ClassMethods)
  end

  it "wraps the target action in a flamegraph" do
    controller_class.flamegraph(:show, ignore_gc: true, interval: 500)

    expect(controller_class.around_actions.size).to eq(1)
    options, callback = controller_class.around_actions.first
    expect(options).to eq(only: :show)

    controller = controller_class.new
    allow(controller).to receive(:flamegraph) { |**, &action| action.call }
    action_ran = false

    callback.call(controller, -> { action_ran = true })

    expect(controller).to have_received(:flamegraph).with(ignore_gc: true, interval: 500)
    expect(action_ran).to be(true)
  end
end
