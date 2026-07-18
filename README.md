# EventEngine::Definition

The plain-Ruby event-definition contract for the [EventEngine](https://github.com/DYB-Development/event_engine) pipeline.

EventEngine is a schema-first event pipeline: domain events are **declared** with a Ruby DSL, **compiled** into a canonical schema, and **emitted** through generated helper methods that hand each event to a publisher. This gem holds the plain-Ruby foundation of that pipeline — the `EventEngine::EventDefinition` DSL, the shared schema value objects, and the build step that turns a set of definitions into a committed helper file — with **no Rails dependency**.

Lightweight domain-pack gems depend on this contract; the full dispatch, registry, and Rails-engine machinery lives in [`event_engine`](https://github.com/DYB-Development/event_engine) and is wired in at runtime.

## Installation

Requires Ruby `>= 3.2.0`.

Add the gem to your Gemfile:

```ruby
gem "event_engine-definition"
```

Then run `bundle install`, and require it:

```ruby
require "event_engine/definition"
```

## Usage

### 1. Declare an event

Subclass `EventEngine::EventDefinition` and describe the event with the DSL. `input`s name the objects the event is built from; `payload` fields pull attributes off those inputs into the emitted event.

```ruby
require "event_engine/definition"

class LeadCreated < EventEngine::EventDefinition
  event_name :lead_created   # snake_case identity
  event_type :domain
  domain     :marketing

  input          :lead       # required input
  optional_input :campaign   # optional input

  required_payload :email, from: :lead, attr: :email
  optional_payload :source, from: :campaign, attr: :source
end
```

Every definition compiles to a `Schema` value object:

```ruby
schema = LeadCreated.schema

schema.event_name    # => :lead_created
schema.required_inputs  # => [:lead]
schema.fingerprint   # => "…sha256 of the event's structure…"
schema.to_h          # => plain data hash (JSON-safe)
schema.to_ruby       # => a Ruby source string that rebuilds the Schema
```

The fingerprint is a stable hash of the event's **structure** (name, type, inputs, payload) — so incidental fields like `domain` don't change it, and a matching fingerprint means a matching contract.

### 2. Generate a whole lifecycle (optional)

`LifecycleDefinition` stamps out one snake_case event per verb from a shared base, with per-verb overrides via `on`:

```ruby
class ExportCsv < EventEngine::LifecycleDefinition
  subject    :export_csv
  event_type :product

  input :export
  required_payload :format, from: :export, attr: :format

  lifecycle :started, :completed, :failed

  on :failed do
    input :error
    required_payload :error_class, from: :error, attr: :class
  end
end

ExportCsv.generated_events.map { |event| event.schema.event_name }
# => [:export_csv_started, :export_csv_completed, :export_csv_failed]
```

### 3. Build a domain pack

`DomainPackBuild.run` compiles a set of definitions and writes two files next to each other:

```ruby
EventEngine::DomainPackBuild.run(
  [LeadCreated],
  helper_path: "app/generated/marketing_events.rb",
  root_module: "MarketingEvents"
)
```

This produces:

- **`marketing_events.rb`** — a flat helper module. Each event becomes a typed method that emits through the publisher port:

  ```ruby
  module MarketingEvents
    def self.schema_path
      File.expand_path("schema.json", __dir__)
    end

    def self.lead_created(lead:, campaign: nil, event_version: nil, occurred_at: nil, ...)
      EventEngine::Definition.publisher.publish(
        :lead_created,
        domain: :marketing,
        inputs: { lead: lead, campaign: campaign },
        event_version: event_version,
        ...
      )
    end
  end
  ```

- **`schema.json`** — the canonical, committed schema for the pack (one entry per event, each carrying its fingerprint). This file is authoritative in production; it is generated, not hand-edited.

Compilation validates the definitions as it goes: event names must be snake_case, input names may not collide with reserved envelope keys (`event_version`, `occurred_at`, `metadata`, `idempotency_key`, `aggregate_type`, `aggregate_id`, `aggregate_version`), and any declared `subject` must be registered (see `EventEngine::SubjectRegistry`).

### 4. Emit through a publisher

The generated helpers call `EventEngine::Definition.publisher.publish`. Out of the box the publisher is a `NullPublisher` that raises until one is configured:

```ruby
MarketingEvents.lead_created(lead: some_lead)
# => EventEngine::Definition::PublisherNotConfigured

EventEngine::Definition.publisher = my_publisher   # any object with #publish(event_name, **envelope)
MarketingEvents.lead_created(lead: some_lead)       # now dispatches
```

## How it fits with `event_engine`

This gem defines and generates; `event_engine` runs. The seam between them is the **publisher port** (`EventEngine::Definition.publisher`):

```
this gem                                    event_engine (host runtime)
────────────────────────────────           ──────────────────────────────
EventDefinition DSL                          registers as the publisher
        │ compile                            ────────────────────►
        ▼                                    dispatches each published
generated helper  ──publish(event)──►        event to its handlers,
+ committed schema.json                       persistence, brokers, etc.
```

A domain pack depends only on `event_engine-definition` to declare its events and build its helper file. In an app that also has `event_engine` installed, `event_engine` provides a real publisher adapter and assigns it to `EventEngine::Definition.publisher`, so calling a generated helper hands the event to the full runtime. Nothing in this gem knows how events are dispatched — that decision lives entirely in `event_engine`.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then:

- `rake test` — run the test suite
- `bin/console` — an interactive prompt with the gem loaded

## License

Available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
