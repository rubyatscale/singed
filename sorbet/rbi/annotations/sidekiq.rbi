# typed: true

# DO NOT EDIT MANUALLY
# This file was pulled from a central RBI files repository.
# Please run `bin/tapioca annotations` to update it.

class Sidekiq::CLI
  sig { returns(Sidekiq::Launcher) }
  def launcher; end

  sig { returns(Sidekiq::CLI) }
  def self.instance; end
end

class Sidekiq::Client
  sig { params(item: T.untyped).returns(T.untyped) }
  def normalize_item(item); end

  sig { params(item_class: T.untyped).returns(T.untyped) }
  def normalized_hash(item_class); end
end

class Sidekiq::DeadSet < ::Sidekiq::JobSet
  Elem = type_member { { fixed: Sidekiq::SortedEntry } }
end

class Sidekiq::JobSet < ::Sidekiq::SortedSet
  Elem = type_member { { fixed: Sidekiq::SortedEntry } }
end

class Sidekiq::Launcher
  sig { returns(T::Boolean) }
  def stopping?; end
end

class Sidekiq::Middleware::Chain
  Elem = type_member { { fixed: T.untyped } }
end

class Sidekiq::ProcessSet
  Elem = type_member { { fixed: Sidekiq::Process } }
end

class Sidekiq::Queue
  Elem = type_member { { fixed: Sidekiq::Job } }

  sig { returns(T::Boolean) }
  def paused?; end

  sig { returns(Integer) }
  def size; end
end

class Sidekiq::RetrySet < ::Sidekiq::JobSet
  Elem = type_member { { fixed: Sidekiq::SortedEntry } }
end

class Sidekiq::ScheduledSet < ::Sidekiq::JobSet
  Elem = type_member { { fixed: Sidekiq::SortedEntry } }
end

class Sidekiq::SortedSet
  Elem = type_member { { fixed: Sidekiq::SortedEntry } }
end

module Sidekiq::Job
  sig { returns(String) }
  def jid; end
end

module Sidekiq::Job::ClassMethods
  sig { params(args: T.untyped).returns(String) }
  def perform_async(*args); end

  sig { params(interval: T.untyped, args: T.untyped).returns(String) }
  def perform_at(interval, *args); end

  sig { params(interval: T.untyped, args: T.untyped).returns(String) }
  def perform_in(interval, *args); end
end

class Sidekiq::WorkSet
  Elem = type_member { { fixed: T.untyped } }
end
