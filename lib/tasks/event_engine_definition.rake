require "event_engine/definition"

namespace :event_engine do
  namespace :definition do
    desc "Generate the pack's helper and schema.json from its EventDefinitions"
    task :dump do
      config = EventEngine::Definition.configuration

      definitions = EventEngine::DefinitionLoader.load!(config.definitions_path)

      EventEngine::DomainPackBuild.run(
        definitions,
        helper_path: config.helper_path,
        root_module: config.root_module,
        subject_registry: config.subject_registry
      )
    end
  end
end
