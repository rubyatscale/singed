# typed: strict
# frozen_string_literal: true

require "active_support/concern"

module Singed
  module ControllerExt
    extend ActiveSupport::Concern

    # Concern extends the including controller class with this module; controllers define around_action.
    # @requires_ancestor: AbstractController::Callbacks::ClassMethods
    module ClassMethods
      # Define an around_action to generate flamegraph for a controller action.
      #: (Symbol | String | Array[Symbol | String], ?ignore_gc: bool, ?interval: Integer, ?profiler: Symbol?) -> void
      def flamegraph(target_action, ignore_gc: false, interval: 1000, profiler: nil)
        around_action(only: target_action) do |controller, action|
          controller.flamegraph(ignore_gc:, interval:, profiler:, &action)
        end
      end
    end
  end
end
