module Dagoba
  class Pipe
    class Relationship < Pipe
      def initialize(graph, args)
        super

        @relationship_type = args[:relationship_type]
        unless graph.has_relationship?(@relationship_type)
          raise ArgumentError.new("Invalid relationship #{@relationship_type}")
        end

        @edges = []
      end

      def next(maybe_gremlin)
        return Commands::PULL if !maybe_gremlin && out_of_edges?

        if out_of_edges?
          @gremlin = maybe_gremlin
          retrieve_edges
          return Commands::PULL if out_of_edges?
        end

        next_vertex = @edges.pop.end_vertex
        @gremlin.go_to_vertex(next_vertex)
      end

      private

      def out_of_edges?
        @edges.empty?
      end

      def retrieve_edges
        return if @gremlin.vertex.nil?

        @edges = @gremlin.vertex.relations.select { |r| r.relationship_type == @relationship_type }
      end
    end
  end
end
