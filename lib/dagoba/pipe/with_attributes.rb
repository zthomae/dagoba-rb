module Dagoba
  class Pipe
    class WithAttributes < Pipe
      def initialize(graph, args)
        super

        @attributes = args[:attributes]
      end

      def next(maybe_gremlin)
        return Commands::PULL unless maybe_gremlin

        @attributes.each do |key, value|
          return Commands::PULL if maybe_gremlin.vertex.attributes[key] != value
        end

        maybe_gremlin
      end
    end
  end
end
