# frozen_string_literal: true

require "event_engine/dsl_compiler"
require "event_engine/subject_registry"
require "event_engine/event_engine_helpers_writer"

module EventEngine
  class DomainPackBuild
    PORT_EMIT = "EventEngine::Definition.publisher.publish"

    HEADER = <<~RUBY.freeze
      # This file is authoritative in production.
      # It is generated from this pack's EventDefinitions.
      # Do not edit manually.

    RUBY

    def self.run(definitions, helper_path:, root_module:, header: HEADER,
                 subject_registry: SubjectRegistry.new)
      new(
        definitions,
        helper_path: helper_path,
        root_module: root_module,
        header: header,
        subject_registry: subject_registry
      ).run
    end

    def initialize(definitions, helper_path:, root_module:, header:, subject_registry:)
      @definitions = definitions
      @helper_path = helper_path
      @root_module = root_module
      @header = header
      @subject_registry = subject_registry
    end

    def run
      write_helper(compile)
      self
    end

    private

    def compile
      DslCompiler.compile(@definitions, subject_registry: @subject_registry).event_schema
    end

    def write_helper(event_schema)
      EventEngineHelpersWriter.write(
        @helper_path,
        event_schema,
        root_module: @root_module,
        emit: PORT_EMIT,
        header: @header,
        group_by_domain: false
      )
    end
  end
end
