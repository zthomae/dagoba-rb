require_relative "./graph"

class FindCommand
  def initialize(graph:, start_vertex_id:)
    @graph = graph
    @relationship_types = graph.instance_variable_get(:@relationship_types)
    @start_vertex = graph.send(:find_vertex, start_vertex_id)
    @state = [@start_vertex]
  end

  def run
    @state.map(&:node)
  end

  private

  def method_missing(symbol, *args)
    if @relationship_types.has_key?(symbol)
      @state = @state.flat_map { |vertex|
        vertex.relations.select { |r| r.relationship_type == symbol }.map { |edge| edge.end_vertex }
      }
      self
    else
      super
    end
  end

  def respond_to_missing?(method_name, include_private = false)
    @relationship_types.has_key?(symbol) || super
  end
end
