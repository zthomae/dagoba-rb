module Graph
  Vertex = Struct.new(:id, :attributes, :relations, keyword_init: true)
  Edge = Struct.new(:relationship_type, :start_vertex, :end_vertex, keyword_init: true)
end
