module Graph
  Vertex = Struct.new(:attributes, :relations, keyword_init: true) {
    def id
      attributes[:id]
    end
  }
  Edge = Struct.new(:relationship_type, :start_vertex, :end_vertex, keyword_init: true)
end
