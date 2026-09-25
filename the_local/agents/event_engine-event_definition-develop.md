---
name: event_engine-event_definition-develop
description: Use PROACTIVELY for declaring a domain event, declaring a lifecycle family of events (created / updated / failed and the like) for one subject, registering the subjects events are about, reading an event's compiled schema or fingerprint, setting where raised events are published, and listing the loaded packs and their schema.json files — MUST BE USED instead of hand-writing event hashes, event name constants, emit helpers or a schema file.
tools: Read, Write, Edit, Grep
scope: declaring domain events with a plain-Ruby DSL and generating a pack's typed helper module and committed schema.json from them
---

You write and change a pack's event definitions, subjects and publisher wiring by
following the steps below. Where a step says to ask the developer, ask and wait
for the answer, and after every change to a definition you regenerate and commit
the pack's helper and `schema.json`.

## What event_engine-event_definition is

A plain-Ruby gem, with no Rails dependency, in which each domain event is declared
once as a small Ruby class naming the event, the inputs a caller passes, and the
payload fields the event carries. Generation turns every definition into a typed
helper method on the pack's root module and one entry in a committed
`schema.json`.

Fire this local when someone adds, changes or removes an event, adds a subject,
asks what an event's contract is, or needs raised events to go somewhere. Adding
the gem, configuring its paths and loading its rake task belongs to the install
local.

## Interface

- `EventEngine::EventDefinition` — subclass it to declare one event with
  `event_name`, `event_type`, `domain`, `subject`, `input`, `optional_input`,
  `required_payload` and `optional_payload`.
- `EventEngine::LifecycleDefinition` — subclass it to declare one event per verb
  for a subject with `subject`, `event_type`, `lifecycle`, `on`, the input
  declarations and the payload declarations.
- `EventEngine::SubjectRegistry.define` — builds a registry of every subject an
  event may name, from a block of `subject :name, **metadata` lines.
- `EventEngine::EventDefinition.schema` — called on a definition class, returns
  its validated schema, or raises `ArgumentError` listing every problem.
- `EventEngine::Definition.publisher=` — sets the object every generated helper
  hands its event to.
- `EventEngine::Definition.packs` — the root modules of every generated helper
  required so far, each listed once.
- `EventEngine::Definition.pack_schema_paths` — the absolute `schema.json` path
  of each of those packs.

## How to use it

### Declare one event

1. Put the definition in a `.rb` file anywhere under the pack's definitions path,
   which is the `definitions_path` in the pack's configuration. Every
   `.rb` file under it, at any depth, is loaded, so one class per file is enough.
2. Subclass `EventEngine::EventDefinition` and declare the identity:

   ```ruby
   class LeadCreated < EventEngine::EventDefinition
     event_name :lead_created
     event_type :domain
     domain :marketing
     subject :lead
   ```

   - `event_name` is required and must be a snake_case symbol. It becomes the
     helper method's name.
   - `event_type` is required. It is a classification symbol with no fixed list,
     so ask the developer which value the pack uses, such as `:domain` or
     `:product`.
   - `domain` is optional. Two events may share an `event_name` only in different
     domains, and generation raises a duplicate error otherwise. Ask the
     developer which domain the event belongs to.
   - `subject` is optional. When set, it must be in the pack's subject registry,
     or generation raises `EventEngine::SubjectRegistry::UnknownSubjectError`.
3. Declare the inputs. Each input is one keyword argument on the generated
   helper, and it holds the whole object the caller already has:

   ```ruby
     input :lead
     optional_input :campaign
   ```

   - `input` makes the keyword required. `optional_input` defaults it to `nil`.
   - Declaring the same name twice raises `ArgumentError` at once.
   - An input may not be named `event_version`, `occurred_at`, `metadata`,
     `idempotency_key`, `aggregate_type`, `aggregate_id` or `aggregate_version`,
     since the helper already takes those keywords.
4. Declare the payload fields, the flat values the event carries, each read off
   one input:

   ```ruby
     required_payload :lead_id, from: :lead, attr: :id
     required_payload :email,   from: :lead, attr: :email
     optional_payload :source,  from: :campaign, attr: :channel
   end
   ```

   - `from:` is required and must name an input declared on the same class.
   - `attr:` names the attribute read off that input.
   - `required_payload` marks the field as always present, and
     `optional_payload` marks it as possibly absent. Ask the developer which one
     each field is, because the choice is part of the event's contract.
   - Field names must be unique within the event and may not be `event_name`,
     `event_type`, `event_version`, `occurred_at`, `created_at`, `updated_at`,
     `published_at`, `metadata`, `idempotency_key`, `attempts`,
     `dead_lettered_at`, `aggregate_type`, `aggregate_id` or `aggregate_version`.
   - The definition records the mapping only. Reading `lead.id` and the rest is
     done by whichever publisher receives the event.
5. Check the definition by calling `LeadCreated.schema`. It raises
   `ArgumentError` naming every missing identity field, duplicate field,
   reserved field name, missing `from:` and unknown input.

### Declare a lifecycle family

Use this when one subject has several events that share their inputs and
payload, such as a started, completed and failed step.

1. Put it under the definitions path like any other definition.
2. Subclass `EventEngine::LifecycleDefinition`:

   ```ruby
   class ImportLifecycle < EventEngine::LifecycleDefinition
     subject :import
     event_type :domain
     lifecycle :started, :completed, :failed

     input :import
     required_payload :import_id, from: :import, attr: :id

     on :failed do
       domain :data
       optional_input :error
       optional_payload :error_message, from: :error, attr: :message
     end
   end
   ```

   - Each verb becomes one event named `<subject>_<verb>`, such as
     `import_started`, so the subject and every verb must be snake_case.
   - Every generated event takes the family's `subject`, `event_type`, inputs
     and payload fields.
   - The subject must be in the pack's subject registry.
   - A `lifecycle` family has no `domain` of its own. Each generated event has
     no domain unless its `on` block sets one, so ask the developer whether the
     family's events need a domain, and if they do, add an `on` block for every
     verb that calls `domain`.
3. Use `on :<verb> do ... end` to add to one verb's event. The block takes every
   declaration from "Declare one event", and it may override `event_type`. An
   `on` block for a verb missing from `lifecycle` has no effect.
4. Re-declaring an input the family already declares raises `ArgumentError`.

### Register subjects

Do this whenever any event or lifecycle family names a `subject`.

1. Build the registry with every subject used across the pack:

   ```ruby
   SUBJECTS = EventEngine::SubjectRegistry.define do
     subject :lead
     subject :import, owner: "data team"
   end
   ```

   Metadata after the name is optional and free-form. Ask the developer whether
   any subject needs it.
2. Hand the registry to generation as the pack's configured `subject_registry`,
   such as `config.subject_registry = SUBJECTS`. If the pack has no
   configuration yet, the install local sets it up.

### Regenerate after every change

1. Run the pack's generation task, which the install local sets up, from the
   project root. It raises instead of writing if any definition is invalid.
2. Commit the regenerated helper and `schema.json` together with the definition
   change.
3. Raise the event from consuming code through the generated helper on the
   pack's root module, passing the inputs as keywords:

   ```ruby
   MarketingEvents.lead_created(lead: lead, campaign: campaign)
   ```

   Each helper also takes the optional keywords `event_version`, `occurred_at`,
   `metadata`, `idempotency_key`, `aggregate_type`, `aggregate_id` and
   `aggregate_version`, which are passed to the publisher unchanged.

### Read an event's contract

Call `.schema` on the definition class and read from the result:

```ruby
schema = LeadCreated.schema
schema.event_name       # => :lead_created
schema.required_inputs  # => [:lead]
schema.optional_inputs  # => [:campaign]
schema.payload_fields   # => [{ name: :lead_id, required: true, from: :lead, attr: :id }, ...]
schema.fingerprint      # => a SHA-256 hex string
schema.to_h             # => the same hash written into schema.json
```

The fingerprint covers the event name, event type, inputs and payload fields,
including whether each field is required. A change to any of those changes the
fingerprint, and a change to `domain` or `subject` does not. Compare fingerprints
to tell whether an event's contract changed.

### Set the publisher

1. Ask the developer whether the host app has the `event_engine` gem installed.
   If it does, it sets the publisher at boot and nothing is written here.
2. Otherwise, until a publisher is set, every generated helper raises
   `EventEngine::Definition::PublisherNotConfigured`. Ask the developer where
   raised events should go, then write a publisher that responds to:

   ```ruby
   def publish(event_name, domain:, inputs:, event_version:, occurred_at:,
               metadata:, idempotency_key:, aggregate_type:, aggregate_id:,
               aggregate_version:)
   ```

   `event_name` and `domain` are symbols, and `inputs` is a hash of the input
   objects exactly as the caller passed them, keyed by input name. The publisher
   builds the payload from them using the event's `from:` and `attr:` mapping.
3. Assign it once at boot, after the gem is required and before any helper is
   called:

   ```ruby
   EventEngine::Definition.publisher = MyPublisher.new
   ```

4. In a test that raises events, assign a publisher that records its calls and
   assert on those calls.

### List the loaded packs

1. Require every pack's generated helper first. A pack is listed only after its
   helper has been required, and requiring one twice lists it once.
2. Read `EventEngine::Definition.packs` for the pack root modules, such as
   `[MarketingEvents, SalesEvents]`.
3. Read `EventEngine::Definition.pack_schema_paths` for the absolute path of each
   pack's `schema.json`, in the same order.

## Conventions

- Every definition declares `event_name` and `event_type`, and every payload
  field declares `from:`.
- Every `subject` used anywhere in the pack is in its subject registry.
- Never edit the generated helper or `schema.json` by hand. Regenerate and commit
  both after every definition change.
- Raise events only through the generated helpers, never by calling the publisher
  directly.
- A definition describes what an event carries, never what happens to it. How a
  raised event is processed belongs to the publisher.
- Adding the gem, loading the rake task and setting `definitions_path`,
  `helper_path` and `root_module` is out of scope here and belongs to the install
  local.
