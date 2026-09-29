# typed: true
# frozen_string_literal: true

require "action_controller"
require "active_job"
require "json"
require "optionparser"
require "rack"
require "rails"
require "rbconfig"
require "shellwords"
require "sidekiq/api"
require "sidekiq/testing"
require "stackprof"
require "tempfile"
require "tmpdir"
require "vernier"
require "zeitwerk"
