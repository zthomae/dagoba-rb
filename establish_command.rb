require_relative "./graph"

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
    Graph::Edge.new(
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
