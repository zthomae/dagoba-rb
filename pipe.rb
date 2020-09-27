class Pipe
  module Commands
    DONE = "done"
    PULL = "pull"
  end

  class Gremlin
    attr_reader :vertex, :state

    def initialize(vertex:, state: {})
      @vertex = vertex
      @state = state
    end

    def go_to_vertex(new_vertex)
      Gremlin.new(vertex: new_vertex, state: @state)
    end
  end

  def initialize(graph, args)
    @graph = graph
    @args = args
  end

  def next(maybe_gremlin)
    maybe_gremlin || Commands::PULL
  end
end

class Vertices < Pipe
  def initialize(graph, args)
    super

    # TODO: Support more complex search queries, and remove private method call
    @vertices = args.map { |vertex_id| graph.send(:find_vertex, vertex_id) }
  end

  def next(maybe_gremlin)
    return Commands::DONE if @vertices.empty?

    next_vertex = @vertices.pop
    # TODO: Why is this gremlin assumed to exist in the text?
    if maybe_gremlin
      maybe_gremlin.go_to_vertex(next_vertex)
    else
      Pipe::Gremlin.new(vertex: next_vertex)
    end
  end
end

class Relationship < Pipe
  def initialize(graph, args)
    super

    @relationship_type = args[:relationship_type]
    unless graph.has_relationship?(@relationship_type)
      raise ArgumentError.new("Invalid relationship #{@relationship_type}")
    end

    @edges = []
  end

  def next(maybe_gremlin)
    return Commands::PULL if !maybe_gremlin && out_of_edges?

    if out_of_edges?
      @gremlin = maybe_gremlin
      retrieve_edges
      return Commands::PULL if out_of_edges?
    end

    next_vertex = @edges.pop.end_vertex
    @gremlin.go_to_vertex(next_vertex)
  end

  private

  def out_of_edges?
    @edges.empty?
  end

  def retrieve_edges
    @edges = @gremlin.vertex.relations.select { |r| r.relationship_type == @relationship_type }
  end
end
