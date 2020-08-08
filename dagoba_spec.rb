require "rspec"

require_relative "./dagoba"

describe Dagoba do
  describe "adding relationships" do
    it "will not allow you to establish a relationship with no inverse" do
      graph = Dagoba.new
      expect { graph.relationship(:knows) }.to raise_error(ArgumentError)
      expect { graph.relationship(:knows, inverse: nil) }.to raise_error(ArgumentError)
    end

    it "will not allow you to establish a relationship with an invalid starting vertex" do
      graph = Dagoba.new {
        relationship(:knows, inverse: :knows)
        vertex("end")
      }
      expect { graph.establish("start").knows("end") }.to raise_error(
        "Cannot establish relationship from nonexistent vertex start"
      )
    end

    it "will not allow you to establish a relationship with an invalid type" do
      graph = Dagoba.new {
        vertex "start"
        vertex "end"
      }
      expect { graph.establish("start").knows("end") }.to raise_error(NoMethodError)
    end

    it "will allow you to establish a relationship of a valid type between two vertices" do
      graph = Dagoba.new {
        vertex("start")
        vertex("end")
        relationship(:knows, inverse: :knows)
      }
      expect { graph.establish("start").knows("end") }.not_to raise_error
    end

    it "will allow you to establish inverse relationships" do
      graph = Dagoba.new {
        vertex("start")
        vertex("end")
        relationship(:knows, inverse: :known_by)
      }
      expect { graph.establish("end").known_by("start") }.not_to raise_error
    end

    it "will allow you to establish self-relationships" do
      graph = Dagoba.new {
        vertex("start")
        relationship(:knows, inverse: :knows)
      }
      expect { graph.establish("start").knows("start") }.not_to raise_error
    end

    it "will allow you to establish duplicate relationships" do
      graph = Dagoba.new {
        vertex("start")
        vertex("end")
        relationship(:knows, inverse: :knows)
      }
      expect { graph.establish("start").knows("end") }.not_to raise_error
      expect { graph.establish("start").knows("end") }.not_to raise_error
    end

    it "will allow you to establish multiple relationship types" do
      graph = Dagoba.new {
        vertex("start")
        vertex("end")
        relationship(:knows, inverse: :knows)
        relationship(:is_parent_of, inverse: :is_child_of)
      }
      expect { graph.establish("start").knows("end") }.not_to raise_error
      expect { graph.establish("start").is_parent_of("end") }.not_to raise_error
    end

    it "will not allow you to declare duplicate relationship types" do
      graph = Dagoba.new {
        relationship(:knows, inverse: :knows)
      }
      expect { graph.relationship(:knows, inverse: :knows) }.to raise_error(
        "A relationship type with the name knows already exists"
      )
      expect { graph.relationship(:known_by, inverse: :knows) }.to raise_error(
        "A relationship type with the name knows already exists"
      )
    end
  end

  describe "querying relationships" do
    it "returns empty when a node has no relations of a given type" do
      graph = Dagoba.new {
        relationship(:knows, inverse: :knows)
        vertex("start")
      }
      expect(graph.find("start").knows.run).to be_empty
    end

    it "returns the correct number of results when a node has relations of a given type" do
      graph = Dagoba.new {
        relationship(:knows, inverse: :knows)
        vertex("start")
        vertex("end")
        establish("start").knows("start")
        establish("start").knows("end")
      }
      expect(graph.find("start").knows.run.length).to eq(2)
    end

    it "allows chaining queries" do
      graph = Dagoba.new {
        relationship(:parent_of, inverse: :child_of)
        vertex("alice")
        vertex("bob")
        vertex("charlie")
        establish("alice").parent_of("bob")
        establish("charlie").parent_of("bob")
      }
      expect(graph.find("alice").parent_of.child_of.run.length).to eq(2)
    end
  end
end
