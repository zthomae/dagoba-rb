require "rspec"

require_relative "./dagoba"
require_relative "./find_command"

describe Dagoba do
  describe "adding relationships" do
    it "will not allow you to establish a relationship with no inverse" do
      graph = Dagoba.new
      expect { graph.relationship(:knows) }.to raise_error(ArgumentError)
      expect { graph.relationship(:knows, inverse: nil) }.to raise_error(ArgumentError)
    end

    it "will not allow you to establish a relationship type that is not a symbol" do
      graph = Dagoba.new
      expect { graph.relationship("knows", inverse: :known_by) }.to raise_error(ArgumentError)
      expect { graph.relationship(:knows, inverse: "known_by") }.to raise_error(ArgumentError)
      expect { graph.relationship("knows", inverse: "known_by") }.to raise_error(ArgumentError)
    end

    FindCommand.reserved_words.each do |word|
      it "will not allow you to establish a relationship type named #{word}" do
        graph = Dagoba.new
        expect { graph.relationship(word, inverse: :foobar) }.to raise_error(ArgumentError)
        expect { graph.relationship(:foobar, inverse: word) }.to raise_error(ArgumentError)
      end
    end

    it "will not allow you to establish a relationship with an invalid starting vertex" do
      graph = Dagoba.new {
        relationship(:knows, inverse: :knows)
        add_entry("end")
      }
      expect { graph.establish("start").knows("end") }.to raise_error(
        "Cannot establish relationship from nonexistent vertex start"
      )
    end

    it "will not allow you to establish a relationship with an invalid type" do
      graph = Dagoba.new {
        add_entry "start"
        add_entry "end"
      }
      expect { graph.establish("start").knows("end") }.to raise_error(NoMethodError)
    end

    it "will allow you to establish a relationship of a valid type between two vertices" do
      graph = Dagoba.new {
        add_entry("start")
        add_entry("end")
        relationship(:knows, inverse: :knows)
      }
      expect { graph.establish("start").knows("end") }.not_to raise_error
    end

    it "will allow you to establish inverse relationships" do
      graph = Dagoba.new {
        add_entry("start")
        add_entry("end")
        relationship(:knows, inverse: :known_by)
      }
      expect { graph.establish("end").known_by("start") }.not_to raise_error
    end

    it "will allow you to establish self-relationships" do
      graph = Dagoba.new {
        add_entry("start")
        relationship(:knows, inverse: :knows)
      }
      expect { graph.establish("start").knows("start") }.not_to raise_error
    end

    it "will allow you to establish duplicate relationships" do
      graph = Dagoba.new {
        add_entry("start")
        add_entry("end")
        relationship(:knows, inverse: :knows)
      }
      expect { graph.establish("start").knows("end") }.not_to raise_error
      expect { graph.establish("start").knows("end") }.not_to raise_error
    end

    it "will allow you to establish multiple relationship types" do
      graph = Dagoba.new {
        add_entry("start")
        add_entry("end")
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
        add_entry("start")
      }
      expect(graph.find("start").knows.run).to be_empty
    end

    it "returns the correct number of results when a node has relations of a given type" do
      graph = Dagoba.new {
        relationship(:knows, inverse: :knows)
        add_entry("start")
        add_entry("end")
        establish("start").knows("start")
        establish("start").knows("end")
      }
      expect(graph.find("start").knows.run).to contain_exactly(
        Graph::Node.new(id: "start", attributes: {}),
        Graph::Node.new(id: "end", attributes: {})
      )
    end

    it "allows chaining queries" do
      graph = Dagoba.new {
        relationship(:parent_of, inverse: :child_of)
        add_entry("alice")
        add_entry("bob")
        add_entry("charlie", {age: 35, education: nil})
        add_attributes("alice", {age: 45, education: "Ph.D"})
        establish("alice").parent_of("bob")
        establish("charlie").parent_of("bob")
      }
      expect(graph.find("alice").parent_of.child_of.run).to contain_exactly(
        Graph::Node.new(id: "alice", attributes: {age: 45, education: "Ph.D"}),
        Graph::Node.new(id: "charlie", attributes: {age: 35, education: nil})
      )
    end

    it "allows filtering queries" do
      graph = Dagoba.new {
        relationship(:parent_of, inverse: :child_of)
        add_entry("alice", {age: 40})
        add_entry("bob", {age: 12})
        add_entry("charlie", {age: 10})
        establish("alice").parent_of("bob")
        establish("alice").parent_of("charlie")
      }
      expect(
        graph.find("alice").parent_of.where { |child| child.attributes[:age] > 10 }.run
      ).to contain_exactly(
        Graph::Node.new(id: "bob", attributes: {age: 12})
      )
    end
  end
end
