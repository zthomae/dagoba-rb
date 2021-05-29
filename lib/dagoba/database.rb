require "dagoba/establish_command"
require "dagoba/find_command"
require "dagoba/graph"

module Dagoba
  class Database
    def initialize(&block)
      @edges = []
      @vertices = []
      @vertex_index = {}
      @relationship_types = {}
      @query_types = {}

      if block
        instance_exec(&block)
      end
    end

    def add_entry(id, attributes = {})
      if @vertex_index.has_key?(id)
        raise "An entry with id #{id} already exists"
      end

      validate_attributes(attributes)

      vertex = Graph::Vertex.new(attributes: attributes.merge(id: id), relations: [])
      @vertices << vertex
      @vertex_index[id] = vertex
    end

    def add_attributes(id, attributes = {})
      unless @vertex_index.has_key?(id)
        raise "An entry with id #{id} does not already exist"
      end

      vertex = @vertex_index[id]
      vertex.attributes.merge!(attributes)
    end

    def relationship(relationship_type, inverse:)
      unless inverse
        raise ArgumentError.new("Must provide inverse relationship type")
      end
      if !relationship_type.is_a?(Symbol)
        raise ArgumentError.new("relationship type #{relationship_type} must be symbol")
      elsif FindCommand.reserved_words.include?(relationship_type)
        raise ArgumentError.new("cannot create relationship type #{relationship_type} -- is a reserved word")
      elsif FindCommand.reserved_words.include?(inverse)
        raise ArgumentError.new("cannot create inverse relationship type #{relationship_type} -- is a reserved word")
      elsif !inverse.is_a?(Symbol)
        raise ArgumentError.new("inverse relationship type #{inverse} must be symbol")
      elsif @relationship_types.has_key?(relationship_type)
        raise "A relationship type with the name #{relationship_type} already exists"
      elsif @relationship_types.has_key?(inverse)
        raise "A relationship type with the name #{inverse} already exists"
      end

      @relationship_types[relationship_type] = inverse
      @relationship_types[inverse] = relationship_type
    end

    def has_relationship?(relationship_type)
      @relationship_types.include?(relationship_type)
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

    def add_query(query_type, &block)
      if !query_type.is_a?(Symbol)
        raise ArgumentError.new("query #{query_type} must be a symbol")
      elsif block.nil?
        raise ArgumentError.new("query must be given a block")
      end

      @query_types[query_type] = block.to_proc
    end

    def query(query_type)
      @query_types[query_type]
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

    def validate_attributes(attributes)
      if attributes.has_key?(:id)
        raise ArgumentError.new("Cannot use id as an attribute")
      end

      attributes.each do |attribute_name, _|
        unless attribute_name.is_a?(Symbol)
          raise ArgumentError.new("Attribute #{attribute_name} must be a symbol")
        end
      end
    end
  end
end
