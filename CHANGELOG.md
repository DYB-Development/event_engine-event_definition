# Changelog

All notable changes to this gem are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.3.0] - 2026-07-29

### Added

- Pack self-registration. A generated pack calls
  `EventEngine::Definition.register_pack(self)` when required, so consumers can
  discover every pack's `schema.json` instead of being handed each path by
  configuration. Exposed as `Definition.packs` and `Definition.pack_schema_paths`.
- The generate task reports the files it wrote.

### Changed

- **Breaking.** `event_engine:definition:dump` is now `event_definition:generate`,
  and `tasks/event_engine_definition.rake` is now `tasks/event_definition.rake`.
  Packs must update the `load` line in their Rakefile. "dump" did not say what the
  task produces, and the `event_engine:` prefix implied a dependency on the runtime
  that this gem does not have.
- **Breaking.** `EventEngine::SchemaRegistry` and `EventEngine::EventSchema` are now
  `EventEngine::Definition::SchemaRegistry` and `EventEngine::Definition::EventSchema`.
  Both previously sat at the top level and shadowed the `event_engine` runtime's own
  classes of the same name on the same require path, so in any app installing both
  gems the runtime silently operated on this gem's classes instead of its own.

### Fixed

- Generating a pack into a path whose directory did not exist raised
  `Errno::ENOENT`. The directory is now created.
- The README recommended generating into `lib/generated/`, which Rails 7.1+
  autoloads. Zeitwerk expects that file to define `Generated::MarketingEvents`, so an
  app following the README booted in development and raised on eager load in
  production. Documented how to keep the helper out of the autoload paths.

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
