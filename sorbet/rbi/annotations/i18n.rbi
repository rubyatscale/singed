# typed: true

# DO NOT EDIT MANUALLY
# This file was pulled from a central RBI files repository.
# Please run `bin/tapioca annotations` to update it.

module I18n::Base
  # A list set through `#available_locales=` is symbolized on the way in, but the
  # fallback to `backend.available_locales` is returned as the backend built it,
  # and a custom backend is free to hand back strings.
  sig { returns(T::Array[T.any(String, Symbol)]) }
  def available_locales; end

  sig { params(value: T.nilable(T.any(String, Symbol, T::Array[T.any(String, Symbol)]))).returns(T.nilable(T.any(String, Symbol, T::Array[T.any(String, Symbol)]))) }
  def available_locales=(value); end

  sig { returns(Symbol) }
  def default_locale; end

  sig { params(value: T.nilable(T.any(String, Symbol))).returns(T.nilable(T.any(String, Symbol))) }
  def default_locale=(value); end

  sig { returns(String) }
  def default_separator; end

  sig { params(value: String).returns(String) }
  def default_separator=(value); end

  sig { returns(T::Boolean) }
  def enforce_available_locales; end

  sig { params(value: T::Boolean).returns(T::Boolean) }
  def enforce_available_locales=(value); end

  sig { returns(T.any(Symbol, FalseClass)) }
  def locale; end

  sig { params(value: T.nilable(T.any(String, Symbol, FalseClass))).returns(T.nilable(T.any(String, Symbol, FalseClass))) }
  def locale=(value); end
end
