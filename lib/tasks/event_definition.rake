require "event_engine/definition"

namespace :event_definition do
  desc "Generate the pack's helper and schema.json from its EventDefinitions"
  task :generate do
    config = EventEngine::Definition.configuration

    definitions = EventEngine::DefinitionLoader.load!(config.definitions_path)

    build = EventEngine::DomainPackBuild.run(
      definitions,
      helper_path: config.helper_path,
      root_module: config.root_module,
      subject_registry: config.subject_registry
    )

    puts "Wrote #{config.root_module} helper to #{config.helper_path}"
    puts "Wrote #{config.root_module} schema to #{build.schema_path}"
  end
end
