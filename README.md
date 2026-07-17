# EventEngine::Definition

The plain-Ruby event-definition contract for the [EventEngine](https://github.com/DYB-Development/event_engine) pipeline.

EventEngine is a schema-first event pipeline: domain events are declared with a Ruby DSL, compiled into a canonical schema, emitted through generated helpers, and dispatched to registered handlers. This gem holds the plain-Ruby foundation of that pipeline — the `EventEngine::EventDefinition` DSL and the shared schema-contract value objects — with no Rails dependency.

Lightweight domain-pack gems depend on this contract instead of the full dispatch, registry, and Rails-engine machinery that lives in `event_engine`.

> **Status:** empty skeleton. The DSL and schema-contract code are moved here in follow-up work; this gem currently establishes only the packaging, namespace, and test setup.

## Installation

Add the gem to your application's Gemfile:

```ruby
gem "event_engine-definition"
```

Then run `bundle install`.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
