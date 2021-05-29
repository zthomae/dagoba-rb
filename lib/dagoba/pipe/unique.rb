module Dagoba
  class Pipe
    class Unique < Pipe
      def initialize(graph, args)
        super

        @seen = {}
      end

      def next(maybe_gremlin)
        return Commands::PULL unless maybe_gremlin
        return Commands::PULL if @seen[maybe_gremlin.vertex.id]

        @seen[maybe_gremlin.vertex.id] = true
        maybe_gremlin
      end
    end
  end
end
