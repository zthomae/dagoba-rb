require_relative "./establish_command"
require_relative "./find_command"
require_relative "./graph"

class Dagoba
  def initialize(&block)
    @edges = []
    @vertices = []
    @vertex_index = {}
    @relationship_types = {}

    if block_given?
      instance_exec(&block)
    end
  end

  def vertex(id, **attributes)
    if @vertex_index.has_key?(id)
      raise "A vertex with id #{id} already exists"
    end

    vertex = Graph::Vertex.new(id: id, attributes: attributes, relations: [])
    @vertices << vertex
    @vertex_index[id] = vertex
  end

  def relationship(relationship_type, inverse:)
    unless inverse
      raise ArgumentError.new("Must provide inverse relationship type")
    end
    if @relationship_types.has_key?(relationship_type)
      raise "A relationship type with the name #{relationship_type} already exists"
    elsif @relationship_types.has_key?(inverse)
      raise "A relationship type with the name #{inverse} already exists"
    end

    @relationship_types[relationship_type] = inverse
    @relationship_types[inverse] = relationship_type
  end

  def establish(start_vertex_id)
    EstablishCommand.new(
      graph: self,
      start_vertex_id: start_vertex_id
    )
  end

  def find(start_vertex_id)
    FindCommand.new(
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
    edge.start_vertex.relations << edge

    inverse_type = @relationship_types[edge.relationship_type]
    if inverse_type != edge.relationship_type || edge.start_vertex != edge.end_vertex
      inverse_edge = Graph::Edge.new(
        relationship_type: inverse_type,
        start_vertex: edge.end_vertex,
        end_vertex: edge.start_vertex
      )
      @edges << inverse_edge
      edge.end_vertex.relations << inverse_edge
    end
  end
end
