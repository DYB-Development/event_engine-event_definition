# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "event_engine/definition"

require "minitest/autorun"
require "minitest/reporters"
require "minitest/focus"

Minitest::Reporters.use!
