# frozen_string_literal: true

require "test_helper"
require "bundler"

class EventEngine::DefinitionTest < Minitest::Test
  GEM_ROOT = File.expand_path("../..", __dir__)

  def test_requiring_the_gem_loads_and_exposes_its_version
    script = 'require "event_engine/definition"; print EventEngine::Definition::VERSION'
    output = Bundler.with_unbundled_env do
      IO.popen(["ruby", "-Ilib", "-e", script], chdir: GEM_ROOT, err: %i[child out], &:read)
    end

    assert_equal EventEngine::Definition::VERSION, output
  end
end
