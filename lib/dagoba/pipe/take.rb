module Dagoba
  class Pipe
    class Take < Pipe
      def initialize(graph, args)
        super

        @count = args[:count]
        @taken = 0
      end

      def next(maybe_gremlin)
        if @count == @taken
          @taken = 0
          return Commands::DONE
        end

        return Commands::PULL unless maybe_gremlin

        @taken += 1
        maybe_gremlin
      end
    end
  end
end
