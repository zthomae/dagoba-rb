require "dagoba/pipe/commands"

require "dagoba/pipe/back"
require "dagoba/pipe/except"
require "dagoba/pipe/filter"
require "dagoba/pipe/mark"
require "dagoba/pipe/merge"
require "dagoba/pipe/relationship"
require "dagoba/pipe/select_attributes"
require "dagoba/pipe/take"
require "dagoba/pipe/unique"
require "dagoba/pipe/vertices"
require "dagoba/pipe/with_attributes"

module Dagoba
  class Pipe
    def initialize(graph, args)
      @graph = graph
      @args = args
    end

    def next(maybe_gremlin)
      maybe_gremlin || Commands::PULL
    end
  end
end
