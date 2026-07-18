require "test_helper"

class HelpersWriterTest < DefinitionTestCase
  def lead_created_definition
    Class.new(EventEngine::EventDefinition) do
      event_name :lead_created
      event_type :domain
      domain :marketing
      input :email
    end
  end

  test "generates a singleton method named after the event" do
    source = EventEngine::Definition::HelpersWriter.generate(
      namespace: "MarketingEvents",
      definitions: [lead_created_definition]
    )

    assert_includes source, "def self.lead_created"
  end
end
