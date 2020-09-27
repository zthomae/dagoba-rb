module Graph
  Node = Struct.new(:id, :attributes, keyword_init: true)
  Vertex = Struct.new(:node, :relations, keyword_init: true)
  Edge = Struct.new(:relationship_type, :start_vertex, :end_vertex, keyword_init: true)
end
