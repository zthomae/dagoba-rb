require "dagoba/gremlin"

module Dagoba
  class Pipe
    class Vertices < Pipe
      def initialize(graph, args)
        super

        # TODO: Support more complex search queries, and remove private method call
        @vertices = args.map { |vertex_id| graph.send(:find_vertex, vertex_id) }
      end

      def next(maybe_gremlin)
        return Commands::DONE if @vertices.empty?

        next_vertex = @vertices.pop
        # TODO: Why is this gremlin assumed to exist in the text?
        if maybe_gremlin
          maybe_gremlin.go_to_vertex(next_vertex)
        else
          Gremlin.new(vertex: next_vertex)
        end
      end
    end
  end
end
