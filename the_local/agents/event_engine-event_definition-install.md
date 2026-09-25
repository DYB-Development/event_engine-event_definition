---
name: event_engine-event_definition-install
description: Use to hook event_engine-event_definition into a project — adding the gem, requiring it, loading its rake task, configuring the definitions path, helper path and root module, and running the generation task.
tools: Bash, Read, Edit
scope: declaring domain events with a plain-Ruby DSL and generating a pack's typed helper module and committed schema.json from them
---

You follow these steps exactly and invent none. Where a step says to ask the
developer, ask and wait for the answer.

## What event_engine-event_definition is

A plain-Ruby gem, with no Rails dependency, that generates a pack's typed helper
module and `schema.json` from its event definitions; hook it into a domain pack
gem or a Rails app that owns a set of events.

## Interface

- `gem "event_engine-event_definition"` — adds the gem to the project's bundle.
- `require "event_engine/definition"` — loads the gem.
- `load "tasks/event_definition.rake"` — adds the `event_definition:generate`
  task to the project's Rakefile.
- `EventEngine::Definition.configure` — sets where definitions are read from,
  where the helper is written, and the name of the module that wraps it.
- `rake event_definition:generate` — writes the helper module and `schema.json`
  from every definition under the definitions path.

## How to use it

1. Ask the developer whether this is a domain pack gem or a Rails app.
2. Add the gem.
   - Rails app: add `gem "event_engine-event_definition"` to the `Gemfile`.
   - Pack gem: add `spec.add_dependency "event_engine-event_definition"` to the
     pack's `*.gemspec`, since the generated helper requires the gem at runtime.
   - Run `bundle install`.
3. Ask the developer for three values. None has a default, and the task fails if
   any is missing.
   - `definitions_path` — the directory holding the event definitions, such as
     `app/event_definitions`. Every `.rb` file under it, at any depth, is loaded.
   - `helper_path` — the file the helper module is written to, such as
     `lib/generated/marketing_events.rb`. `schema.json` is written to the same
     directory.
   - `root_module` — the Ruby constant name that wraps the helpers, such as
     `MarketingEvents`.
4. Add these lines to the project's `Rakefile`, with the three values from step 3:

   ```ruby
   require "event_engine/definition"
   load "tasks/event_definition.rake"

   EventEngine::Definition.configure do |config|
     config.definitions_path = "app/event_definitions"
     config.helper_path      = "lib/generated/marketing_events.rb"
     config.root_module      = "MarketingEvents"
   end
   ```

   The paths are relative to the directory rake is run from, so run it from the
   project root.
5. Ask the developer whether any event declares a subject. If one does, add
   `config.subject_registry = <a registry naming every subject used>` inside the
   `configure` block. Writing that registry is the develop local's job. Without
   it, generation raises an unknown subject error.
6. Make sure the helper is required once at boot, since it registers its pack
   when it is required.
   - Rails app: in `config/application.rb`, add the helper's directory to the
     autoload ignore list, such as
     `config.autoload_lib(ignore: %w[assets tasks generated])`, because the
     helper's file path does not match the constant it defines and eager loading
     fails in production. Then in `config/initializers/event_engine.rb`, require
     the helper, such as
     `require Rails.root.join("lib/generated/marketing_events")`.
   - Pack gem: ask the developer which of the pack's files should require the
     helper, and add the `require` there.
7. Run `bundle exec rake event_definition:generate`. It creates the helper's
   directory if missing and writes two files:
   - the helper module at `helper_path`,
   - `schema.json` next to it.
8. Commit both generated files.

## Conventions

- A successful run prints two lines, `Wrote <root_module> helper to
  <helper_path>` and `Wrote <root_module> schema to <dir>/schema.json`. Confirm
  both files exist.
- Re-run `rake event_definition:generate` after every change to a definition and
  commit the result. Never edit the generated files by hand; each run overwrites
  them.
- With no definitions under `definitions_path`, the task still runs and writes an
  empty module and an empty `schema.json`.
- Writing event definitions, subjects and lifecycle families, and choosing where
  raised events go, is out of scope here and belongs to the develop local.
