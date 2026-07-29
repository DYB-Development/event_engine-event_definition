# frozen_string_literal: true

require "test_helper"

module EventEngine
  class PackRegistrationGenerationTest < DefinitionTestCase
    def event_schema
      Definition::EventSchema.new.tap do |schema|
        schema.register(
          EventDefinition::Schema.new(
            event_name: :cow_fed,
            event_version: 1,
            event_type: :domain,
            domain: :sales,
            required_inputs: [ :cow ],
            optional_inputs: [],
            payload_fields: []
          )
        )
        schema.finalize!
      end
    end

    test "a pack helper registers itself with the definition pack registry" do
      generated = EventEngineHelpersWriter.generate(event_schema, schema_filename: "schema.json")

      assert_includes generated, "EventEngine::Definition.register_pack(self)"
    end

    test "a pack helper requires the definition contract it registers with" do
      generated = EventEngineHelpersWriter.generate(event_schema, schema_filename: "schema.json")

      assert_includes generated, %(require "event_engine/definition")
    end
  end
end
