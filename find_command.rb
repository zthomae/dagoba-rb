require_relative "./graph"
require_relative "./pipe"

class FindCommand
  def self.reserved_words
    instance_methods(false)
  end

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

    results.map do |gremlin|
      gremlin.result || gremlin.vertex.node
    end
  end

  def where(&block)
    @program << Filter.new(@graph, {predicate: block.to_proc})
    self
  end

  def take(count)
    @program << Take.new(@graph, {count: count})
    self
  end

  def as(mark)
    unless mark.is_a?(Symbol)
      raise ArgumentError.new("mark #{mark} must be a symbol")
    end

    @program << Mark.new(@graph, {mark: mark})
    self
  end

  def merge(*marks)
    marks.each do |mark|
      unless mark.is_a?(Symbol)
        raise ArgumentError.new("mark #{mark} must be a symbol")
      end
    end

    @program << Merge.new(@graph, {marks: marks})
    self
  end

  def except(mark)
    unless mark.is_a?(Symbol)
      raise ArgumentError.new("mark #{mark} must be a symbol")
    end

    @program << Except.new(@graph, {mark: mark})
    self
  end

  def unique
    @program << Unique.new(@graph, {})
    self
  end

  def with_attributes(attributes)
    attributes.each do |attribute, _|
      unless attribute.is_a?(Symbol)
        raise ArgumentError.new("attribute #{attribute} must be a symbol")
      end
    end

    @program << WithAttributes.new(@graph, {attributes: attributes})
    self
  end

  def select_attribute(attribute)
    unless attribute.is_a?(Symbol)
      raise ArgumentError.new("attribute #{attribute} must be a symbol")
    end

    @program << SelectAttribute.new(@graph, {attribute: attribute})
    self
  end

  def back(mark)
    unless mark.is_a?(Symbol)
      raise ArgumentError.new("mark #{mark} must be a symbol")
    end

    @program << Back.new(@graph, {mark: mark})
    self
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
