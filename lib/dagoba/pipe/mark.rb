module Dagoba
  class Pipe
    class Mark < Pipe
      def initialize(graph, args)
        super

        @mark = args[:mark]
      end

      def next(maybe_gremlin)
        return Commands::PULL unless maybe_gremlin

        maybe_gremlin.marks[@mark] = maybe_gremlin.vertex
        maybe_gremlin
      end
    end
  end
end
