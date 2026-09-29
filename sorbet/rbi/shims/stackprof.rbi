# typed: strict

class StackProf::Report
  # nil when Singed::Flamegraph#save runs without a profile (e.g. Singed.enabled = false); frames then raises.
  sig { params(data: T.nilable(T::Hash[Symbol, T.untyped])).void }
  def initialize(data)
    @data = data
  end

  # Frame address => frame details (:name, :file, :line, :samples, ...).
  sig { params(sort_by_total: T::Boolean).returns(T::Hash[Integer, T::Hash[Symbol, T.untyped]]) }
  def frames(sort_by_total = false); end
end
