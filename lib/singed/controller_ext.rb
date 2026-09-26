# frozen_string_literal: true

require "active_support/concern"

module Singed
  module ControllerExt
    extend ActiveSupport::Concern

    module ClassMethods
      # Define an around_action to generate flamegraph for a controller action.
      def flamegraph(target_action, ignore_gc: false, interval: 1000)
        around_action(only: target_action) do |controller, action|
          controller.flamegraph(ignore_gc:, interval:, &action)
        end
      end
    end
  end
end
