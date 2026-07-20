require "test_helper"
require "tmpdir"
require "rake"

class DefinitionDumpTaskSmokeTest < DefinitionTestCase
  teardown do
    EventEngine::Definition.reset_configuration!
    Object.send(:remove_const, :DumpProbeCreated) if Object.const_defined?(:DumpProbeCreated, false)
    Rake::Task.clear
  end

  test "the dump task generates the helper from configured definitions" do
    Dir.mktmpdir do |dir|
      definitions_path = File.join(dir, "event_definitions")
      Dir.mkdir(definitions_path)
      File.write(File.join(definitions_path, "dump_probe_created.rb"), <<~RUBY)
        class DumpProbeCreated < EventEngine::EventDefinition
          event_name :dump_probe_created
          event_type :domain
          domain :probe
          input :thing
          required_payload :thing_id, from: :thing, attr: :id
        end
      RUBY

      helper_path = File.join(dir, "generated", "probe_events.rb")
      Dir.mkdir(File.dirname(helper_path))

      EventEngine::Definition.configure do |config|
        config.definitions_path = definitions_path
        config.helper_path = helper_path
        config.root_module = "ProbeEvents"
      end

      Rake.application = Rake::Application.new
      load "tasks/event_engine_definition.rake"
      Rake::Task["event_engine:definition:dump"].invoke

      assert_path_exists helper_path
    end
  end
end
