module Dagoba
  class Pipe
    class Back < Pipe
      def initialize(graph, args)
        super

        @mark = args[:mark]
      end

      def next(maybe_gremlin)
        return Commands::PULL unless maybe_gremlin

        maybe_gremlin.go_to_vertex(maybe_gremlin.marks[@mark])
      end
    end
  end
end
