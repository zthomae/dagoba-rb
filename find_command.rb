require_relative "./graph"

class FindCommand
  def initialize(graph:, start_vertex_id:)
    @graph = graph
    @relationship_types = graph.instance_variable_get(:@relationship_types)
    @program = []
    @start_vertex = graph.send(:find_vertex, start_vertex_id)
  end

  def run
    state = [@start_vertex]
    @program.each do |relationship_type|
      state = state.flat_map { |vertex|
        vertex.relations.select { |r| r.relationship_type == relationship_type }.map { |edge| edge.end_vertex }
      }
    end

    state.map(&:node)
  end

  private

  def method_missing(symbol, *args)
    if @relationship_types.has_key?(symbol)
      @program << symbol
      self
    else
      super
    end
  end

  def respond_to_missing?(method_name, include_private = false)
    @relationship_types.has_key?(symbol) || super
  end
end
