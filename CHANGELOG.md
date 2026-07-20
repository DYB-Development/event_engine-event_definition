# Changelog

All notable changes to this gem are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2026-07-20

First published release of `event_engine-event_definition`, the plain-Ruby
event-definition contract for the EventEngine pipeline.

### Added
- EventDefinition DSL and shared schema-contract value objects (`Schema`,
  `EventSchema`, `SchemaRegistry`, `SubjectRegistry`, `LifecycleDefinition`,
  `DslCompiler`), with no Rails dependency.
- Configurable publisher port (`EventEngine::Definition.publisher`), defaulting
  to a `NullPublisher` that fails loudly until a real adapter is assigned.
- Generated namespaced singleton helper methods that publish domain and input
  payloads through the publisher port.
- `DomainPackBuild`, which writes a flat helper file alongside its `schema.json`
  for a domain pack and exposes a `schema_path` accessor in the generated helper.
- `DefinitionLoader.load!` to require a pack's definition files, including
  lifecycle-generated events.
- `EventEngine::Definition.configure` for pack-generation settings.
- `event_engine:definition:dump` rake task to generate a pack without Rails.

[0.2.0]: https://github.com/DYB-Development/event_engine-event_definition/releases/tag/v0.2.0
