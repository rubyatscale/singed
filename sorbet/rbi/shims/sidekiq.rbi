# typed: strict

module Sidekiq::Job
  # Sidekiq::Job is only ever included into job classes, so its instances respond to Object#class.
  requires_ancestor { Object }
end
