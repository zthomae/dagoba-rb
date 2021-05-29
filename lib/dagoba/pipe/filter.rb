module Dagoba
  class Pipe
    class Filter < Pipe
      def initialize(graph, args)
        super

        @predicate = args[:predicate]
      end

      def next(maybe_gremlin)
        if !maybe_gremlin || !@predicate.call(maybe_gremlin.vertex)
          return Commands::PULL
        end

        maybe_gremlin
      end
    end
  end
end
