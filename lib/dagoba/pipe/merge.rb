require "dagoba/gremlin"

module Dagoba
  class Pipe
    class Merge < Pipe
      def initialize(graph, args)
        super

        @marks = args[:marks]
        @vertices = []
      end

      def next(maybe_gremlin)
        return Commands::PULL if !maybe_gremlin && @vertices.empty?

        if @vertices.empty?
          @vertices = @marks.map { |mark| maybe_gremlin.marks[mark] }.compact
          return Commands::PULL if @vertices.empty?
        end

        if maybe_gremlin
          maybe_gremlin.go_to_vertex(@vertices.pop)
        else
          Gremlin.new(vertex: @vertices.pop)
        end
      end
    end
  end
end
