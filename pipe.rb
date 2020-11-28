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

class Filter < Pipe
  def initialize(graph, args)
    super

    @predicate = args[:predicate]
  end

  def next(maybe_gremlin)
    if !maybe_gremlin || !@predicate.call(maybe_gremlin.vertex.node)
      return Commands::PULL
    end

    maybe_gremlin
  end
end

class Take < Pipe
  def initialize(graph, args)
    super

    @count = args[:count]
    @taken = 0
  end

  def next(maybe_gremlin)
    if @count == @taken
      @taken = 0
      return Commands::DONE
    end

    return Commands::PULL unless maybe_gremlin

    @taken += 1
    maybe_gremlin
  end
end

class Mark < Pipe
  def initialize(graph, args)
    super

    @mark = args[:mark]
  end

  def next(maybe_gremlin)
    return Commands::PULL unless maybe_gremlin

    maybe_gremlin.state[:marks] ||= {}
    maybe_gremlin.state[:marks][@mark] = maybe_gremlin.vertex
    maybe_gremlin
  end
end

class Merge < Pipe
  def initialize(graph, args)
    super

    @marks = args[:marks]
    @vertices = []
  end

  def next(maybe_gremlin)
    return Commands::PULL if !maybe_gremlin && @vertices.empty?

    if @vertices.empty?
      maybe_gremlin.state[:marks] ||= {}
      @vertices = @marks.map { |mark| maybe_gremlin.state[:marks][mark] }.compact
      return Commands::PULL if @vertices.empty?
    end

    if maybe_gremlin
      maybe_gremlin.go_to_vertex(@vertices.pop)
    else
      Pipe::Gremlin.new(vertex: @vertices.pop)
    end
  end
end

class Except < Pipe
  def initialize(graph, args)
    super

    @mark = args[:mark]
  end

  def next(maybe_gremlin)
    return Commands::PULL unless maybe_gremlin

    if maybe_gremlin.state[:marks][@mark] == maybe_gremlin.vertex
      return Commands::PULL
    end

    maybe_gremlin
  end
end

class Unique < Pipe
  def initialize(graph, args)
    super

    @seen = {}
  end

  def next(maybe_gremlin)
    return Commands::PULL unless maybe_gremlin
    return Commands::PULL if @seen[maybe_gremlin.vertex.node.id]

    @seen[maybe_gremlin.vertex.node.id] = true
    maybe_gremlin
  end
end

class WithAttributes < Pipe
  def initialize(graph, args)
    super

    @attributes = args[:attributes]
  end

  def next(maybe_gremlin)
    return Commands::PULL unless maybe_gremlin

    @attributes.each do |key, value|
      return Commands::PULL if maybe_gremlin.vertex.node.attributes[key] != value
    end

    maybe_gremlin
  end
end
