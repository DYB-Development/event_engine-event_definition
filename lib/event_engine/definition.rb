# frozen_string_literal: true

require_relative "definition/version"

require "event_engine/subject_registry"
require "event_engine/event_definition"
require "event_engine/definition_loader"
require "event_engine/event_schema"
require "event_engine/definition/schema_registry"
require "event_engine/lifecycle_definition"
require "event_engine/dsl_compiler"
require "event_engine/definition/configuration"

module EventEngine
  module Definition
    class Error < StandardError; end

    class << self
      attr_writer :publisher

      def publisher
        @publisher ||= NullPublisher.new
      end

      def reset_publisher!
        @publisher = nil
      end

      def packs
        @packs ||= []
      end

      def register_pack(pack)
        packs << pack unless packs.include?(pack)
        pack
      end

      def pack_schema_paths
        packs.map(&:schema_path)
      end

      def reset_packs!
        @packs = nil
      end

      def configuration
        @configuration ||= Configuration.new
      end

      def configure
        yield(configuration)
      end

      def reset_configuration!
        @configuration = nil
      end
    end
  end
end

require "event_engine/definition/null_publisher"
require "event_engine/event_engine_helpers_writer"
require "event_engine/domain_pack_build"
