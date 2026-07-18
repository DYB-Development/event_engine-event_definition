module EventEngine
  module Definition
    class HelpersWriter
      def self.generate(namespace:, definitions:)
        bodies = definitions.map { |definition| method_source(definition.schema) }

        "module #{namespace}\n#{bodies.join("\n")}\nend\n"
      end

      def self.method_source(schema)
        "  def self.#{schema.event_name}\n  end"
      end
    end
  end
end
