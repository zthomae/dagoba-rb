# What I want the API to look like:
#
#   graph = Dagoba.new do
#     vertex "alice"
#     vertex "bob", hobbies: ["asdf", {x: 3}]
#
#     relationship :knows, inverse: :known_by
#     relationship :parent, inverse: :is_parent_of
#
#     establish("bob").knows("alice")
#   end
#
#   graph.vertex("charlie")
#   graph.vertex("delta")
#
#   graph.establish("bob").is_parent_of("charlie")
#   graph.establish("delta").parent("bob")
#   graph.establish("charlie").knows("bob")
#
# When you use the name of the label as a method, you get the edges originating
# from the node you started with.
#
#   graph.find("bob").knows  # returns the node for "alice"
#
# To go in the reverse order, you can either use inverse association names or
# the reverse method:
#
#   graph.find("bob").known_by  # returns the node for "charlie"
#   graph.find("bob").is_parent_of  # returns the node for "delta"
#
# If you grab multiple edges, the chained methods work in exactly the same
# way. You can define aliases to make queries look cleaner. Alias names
# cannot conflict with existing relationship or inverse names.
#
#   graph.relationship_type(:parents).means(:parent)
#   graph.relationship_type(:children).reverses(:parents)
#
#   graph.parents  # returns the nodes for "bob" and "alice"
#   graph.children  # returns the nodes for "charlie" and "bob"
class Dagoba
  Vertex = Struct.new(:id, :attributes, :out, :in, keyword_init: true)
  Edge = Struct.new(:relationship_type, :start_vertex, :end_vertex, keyword_init: true)

  class EstablishCommand
    def initialize(graph:, start_vertex_id:)
      @graph = graph
      @relationship_types = graph.instance_variable_get(:@relationship_types)
      @start_vertex = graph.send(:find_vertex, start_vertex_id)
      if @start_vertex.nil?
        raise "Cannot establish relationship from nonexistent vertex #{start_vertex_id}"
      end
    end

    private

    def create_edge(relationship_type, end_vertex_id)
      end_vertex = @graph.send(:find_vertex, end_vertex_id)
      if end_vertex.nil?
        raise "Cannot establish relationship to nonexistent vertex #{end_vertex_id}"
      end
      Edge.new(
        relationship_type: relationship_type,
        start_vertex: @start_vertex,
        end_vertex: end_vertex
      )
    end

    def method_missing(symbol, *args)
      if @relationship_types.has_key?(symbol)
        args.map { |arg| @graph.send(:create_edge, create_edge(symbol, arg)) }
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      @relationship_types.has_key?(symbol) || super
    end
  end

  def initialize
    @edges = []
    @vertices = []
    @vertex_index = {}
    @relationship_types = {}
  end

  def vertex(id, **attributes)
    if @vertex_index.has_key?(id)
      raise "A vertex with id #{id} already exists"
    end

    vertex = Vertex.new(id: id, attributes: attributes, out: [], in: [])
    @vertices << vertex
    @vertex_index[id] = vertex
  end

  def relationship(relationship_type, inverse: nil)
    if @relationship_types.has_key?(relationship_type)
      raise "A relationship type with the name #{relationship_type} already exists"
    elsif inverse && @relationship_types.has_key?(inverse)
      raise "A relationship type with the name #{inverse} already exists"
    end

    @relationship_types[relationship_type] = inverse
    if inverse
      @relationship_types[inverse] = relationship_type
    end
  end

  def establish(start_vertex_id)
    EstablishCommand.new(
      graph: self,
      start_vertex_id: start_vertex_id
    )
  end

  private

  def find_vertex(vertex_id)
    @vertex_index[vertex_id]
  end

  def create_edge(edge)
    @edges << edge
    edge.start_vertex.out << edge
    edge.end_vertex.in << edge

    if @relationship_types[edge.relationship_type]
      inverse_edge = Edge.new(
        relationship_type: @relationship_types[edge.relationship_type],
        start_vertex: edge.end_vertex,
        end_vertex: edge.start_vertex
      )
      @edges << inverse_edge
      inverse_edge.start_vertex.out << inverse_edge
      inverse_edge.end_vertex.in << inverse_edge
    end
  end
end
