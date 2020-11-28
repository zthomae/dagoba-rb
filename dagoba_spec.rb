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

    it "allows taking vertices", :aggregate_failures do
      graph = Dagoba.new {
        relationship(:parent_of, inverse: :child_of)
        add_entry("alice")
        add_entry("bob")
        add_entry("charlie")
        add_entry("daniel")
        add_entry("emilio")
        add_entry("frank")
        establish("alice").parent_of("bob")
        establish("alice").parent_of("charlie")
        establish("alice").parent_of("daniel")
        establish("alice").parent_of("emilio")
        establish("alice").parent_of("frank")
      }
      # TODO: Should ordering be defined?
      base_query = graph.find("alice").parent_of.take(2)
      expect(base_query.run).to contain_exactly(
        Graph::Node.new(id: "emilio", attributes: {}),
        Graph::Node.new(id: "frank", attributes: {})
      )
      expect(base_query.run).to contain_exactly(
        Graph::Node.new(id: "charlie", attributes: {}),
        Graph::Node.new(id: "daniel", attributes: {})
      )
      expect(base_query.run).to contain_exactly(
        Graph::Node.new(id: "bob", attributes: {})
      )
    end

    it "allows marking nodes and merging them into a single result set" do
      graph = Dagoba.new {
        relationship(:parent_of, inverse: :child_of)
        add_entry("alice")
        add_entry("bob")
        add_entry("charlie")
        add_entry("daniel")
        establish("alice").parent_of("bob")
        establish("bob").parent_of("charlie")
        establish("charlie").parent_of("daniel")
      }
      query = graph.find("daniel")
        .child_of.as(:parent)
        .child_of.as(:grandparent)
        .child_of.as(:great_grandparent)
        .merge(:parent, :grandparent, :great_grandparent)
      expect(query.run).to contain_exactly(
        Graph::Node.new(id: "alice", attributes: {}),
        Graph::Node.new(id: "bob", attributes: {}),
        Graph::Node.new(id: "charlie", attributes: {})
      )
    end

    it "allows marking nodes and excluding them from a result set" do
      graph = Dagoba.new {
        relationship(:parent_of, inverse: :child_of)
        add_entry("alice")
        add_entry("bob")
        add_entry("charlie")
        add_entry("daniel")
        establish("alice").parent_of("bob")
        establish("alice").parent_of("charlie")
        establish("alice").parent_of("daniel")
      }
      query = graph.find("bob").as(:me)
        .child_of
        .parent_of
        .except(:me)
      expect(query.run).to contain_exactly(
        Graph::Node.new(id: "charlie", attributes: {}),
        Graph::Node.new(id: "daniel", attributes: {})
      )
    end

    it "allows making result sets unique" do
      graph = Dagoba.new {
        relationship(:parent_of, inverse: :child_of)
        add_entry("alice")
        add_entry("bob")
        add_entry("charlie")
        add_entry("daniel")
        establish("alice").parent_of("bob")
        establish("alice").parent_of("charlie")
        establish("alice").parent_of("daniel")
      }
      expect(graph.find("alice").parent_of.child_of.unique.run).to contain_exactly(
        Graph::Node.new(id: "alice", attributes: {})
      )
    end

    it "allows selecting results by attribute", :aggregate_failures do
      graph = Dagoba.new {
        relationship(:employee_of, inverse: :employer_of)
        add_entry("alice", {programmer: true, salaried: true})
        add_entry("bob", {programmer: false, salaried: true})
        add_entry("charlie", {programmer: true, salaried: false})
        add_entry("daniel")
        establish("alice").employee_of("daniel")
        establish("bob").employee_of("daniel")
        establish("charlie").employee_of("daniel")
      }
      expect(graph.find("daniel").employer_of.with_attributes({programmer: true}).run).to contain_exactly(
        Graph::Node.new(id: "alice", attributes: {programmer: true, salaried: true}),
        Graph::Node.new(id: "charlie", attributes: {programmer: true, salaried: false})
      )
      expect(graph.find("daniel").employer_of.with_attributes({programmer: true, salaried: false}).run).to contain_exactly(
        Graph::Node.new(id: "charlie", attributes: {programmer: true, salaried: false})
      )
    end

    it "allows selecting attributes in results" do
      graph = Dagoba.new {
        relationship(:employee_of, inverse: :employer_of)
        add_entry("alice", {salary: 100_000})
        add_entry("bob", {salary: 70_000})
        add_entry("charlie", {salary: 1_000_000})
        establish("alice").employee_of("charlie")
        establish("bob").employee_of("charlie")
      }
      expect(graph.find("charlie").employer_of.select_attribute(:salary).run).to contain_exactly(
        100_000,
        70_000
      )
    end
  end
end
