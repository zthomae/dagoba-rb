require_relative "./graph"
require_relative "./pipe"

class FindCommand
  def initialize(graph:, start_vertex_id:)
    @graph = graph
    @program = [Vertices.new(@graph, [start_vertex_id])]
  end

  def run
    max = @program.length - 1
    maybe_gremlin = false
    results = []
    done = -1
    pc = max

    while done < max
      step = @program[pc]
      maybe_gremlin = step.next(maybe_gremlin)
      if maybe_gremlin == Pipe::Commands::PULL
        maybe_gremlin = false
        if pc - 1 > done
          pc -= 1
          next
        else
          done = pc
        end
      elsif maybe_gremlin == Pipe::Commands::DONE
        maybe_gremlin = false
        done = pc
      end

      pc += 1

      if pc > max
        if maybe_gremlin
          results << maybe_gremlin
        end
        maybe_gremlin = false
        pc -= 1
      end
    end

    results.map { |gremlin| gremlin.vertex.node }
  end

  private

  def method_missing(symbol, *args)
    if @graph.has_relationship?(symbol)
      @program << Relationship.new(@graph, {relationship_type: symbol})
      self
    else
      super
    end
  end

  def respond_to_missing?(method_name, include_private = false)
    @graph.has_relationship?(symbol) || super
  end
end
