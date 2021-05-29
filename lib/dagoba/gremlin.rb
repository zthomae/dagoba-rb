module Dagoba
  class Gremlin
    attr_reader :vertex, :marks
    attr_accessor :transform

    def initialize(vertex:, marks: {})
      @vertex = vertex
      @marks = marks
      @transform = nil
    end

    def go_to_vertex(new_vertex)
      Gremlin.new(vertex: new_vertex, marks: marks)
    end

    def result
      if transform
        transform.call(vertex.attributes)
      else
        vertex.attributes
      end
    end
  end
end
