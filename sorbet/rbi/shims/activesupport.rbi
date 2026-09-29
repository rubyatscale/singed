# typed: strict

class ActiveSupport::BacktraceCleaner
  # BacktraceCleaner#initialize sets these; lib/singed/backtrace_cleaner_ext.rb reads them.
  sig { void }
  def initialize
    @filters = T.let([], T::Array[T.proc.params(line: String).returns(String)])
    # Silencers are only tested for truthiness.
    @silencers = T.let([], T::Array[T.proc.params(line: String).returns(T.anything)])
  end
end
