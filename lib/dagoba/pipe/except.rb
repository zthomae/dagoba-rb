module Dagoba
  class Pipe
    class Except < Pipe
      def initialize(graph, args)
        super

        @mark = args[:mark]
      end

      def next(maybe_gremlin)
        return Commands::PULL unless maybe_gremlin

        if maybe_gremlin.marks[@mark] == maybe_gremlin.vertex
          return Commands::PULL
        end

        maybe_gremlin
      end
    end
  end
end
