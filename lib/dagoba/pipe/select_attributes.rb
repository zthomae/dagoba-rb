module Dagoba
  class Pipe
    class SelectAttributes < Pipe
      def initialize(graph, args)
        super

        @attributes = args[:attributes]
      end

      def next(maybe_gremlin)
        return Commands::PULL unless maybe_gremlin

        maybe_gremlin.transform = ->(attributes) { attributes.slice(*@attributes) }
        maybe_gremlin
      end
    end
  end
end
