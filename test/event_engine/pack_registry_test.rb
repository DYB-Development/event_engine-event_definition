# frozen_string_literal: true

require "test_helper"

class EventEngine::PackRegistryTest < DefinitionTestCase
  teardown { EventEngine::Definition.reset_packs! }

  test "register_pack adds the pack to packs" do
    pack = Module.new

    EventEngine::Definition.register_pack(pack)

    assert_equal [ pack ], EventEngine::Definition.packs
  end

  test "register_pack ignores a pack that is already registered" do
    pack = Module.new
    EventEngine::Definition.register_pack(pack)

    EventEngine::Definition.register_pack(pack)

    assert_equal [ pack ], EventEngine::Definition.packs
  end

  test "pack_schema_paths collects the schema path of every registered pack" do
    pack = Module.new { def self.schema_path = "/packs/marketing/schema.json" }
    EventEngine::Definition.register_pack(pack)

    assert_equal [ "/packs/marketing/schema.json" ], EventEngine::Definition.pack_schema_paths
  end
end
