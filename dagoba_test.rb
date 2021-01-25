require "minitest/autorun"

require_relative "./dagoba"
require_relative "./find_command"

class TestDagoba < MiniTest::Test
  def assert_query_matches(query, expected_result, sort_by: :id)
    assert_equal(
      expected_result.sort_by { |n| n[sort_by] },
      query.run.sort_by { |n| n[sort_by] }
    )
  end

  def test_relationship_must_have_inverse
    graph = Dagoba.new
    assert_raises(ArgumentError) { graph.relationship(:knows) }
    assert_raises(ArgumentError) { graph.relationship(:knows, inverse: nil) }
  end

  def test_relationship_type_must_be_symbol
    graph = Dagoba.new
    assert_raises(ArgumentError) { graph.relationship("knows", inverse: :known_by) }
    assert_raises(ArgumentError) { graph.relationship(:knows, inverse: "known_by") }
    assert_raises(ArgumentError) { graph.relationship("knows", inverse: "known_by") }
  end

  FindCommand.reserved_words.each do |word|
    define_method "test_cannot_establish_relationship_named_#{word}" do
      graph = Dagoba.new
      assert_raises(ArgumentError) { graph.relationship(word, inverse: :foobar) }
      assert_raises(ArgumentError) { graph.relationship(:foobar, inverse: word) }
    end
  end

  def test_relationship_must_have_valid_starting_index
    graph = Dagoba.new {
      relationship(:knows, inverse: :knows)
      add_entry("end")
    }
    assert_raises("Cannot establish relationship from nonexistent vertex start") do
      graph.establish("start").knows("end")
    end
  end

  def test_cannot_establish_relationship_with_invalid_type
    graph = Dagoba.new {
      add_entry "start"
      add_entry "end"
    }
    assert_raises(NoMethodError) { graph.establish("start").knows("end") }
  end

  def test_can_establish_relationship_between_two_vertices
    graph = Dagoba.new {
      add_entry("start")
      add_entry("end")
      relationship(:knows, inverse: :knows)
    }
    graph.establish("start").knows("end")
  end

  def test_can_establish_inverse_relationships
    graph = Dagoba.new {
      add_entry("start")
      add_entry("end")
      relationship(:knows, inverse: :known_by)
    }
    graph.establish("end").known_by("start")
  end

  def test_can_establish_self_relationships
    graph = Dagoba.new {
      add_entry("start")
      relationship(:knows, inverse: :knows)
    }
    graph.establish("start").knows("start")
  end

  def test_can_establish_duplicate_relationships
    graph = Dagoba.new {
      add_entry("start")
      add_entry("end")
      relationship(:knows, inverse: :knows)
    }
    graph.establish("start").knows("end")
    graph.establish("start").knows("end")
  end

  def test_can_establish_multiple_relationship_types
    graph = Dagoba.new {
      add_entry("start")
      add_entry("end")
      relationship(:knows, inverse: :knows)
      relationship(:is_parent_of, inverse: :is_child_of)
    }
    graph.establish("start").knows("end")
    graph.establish("start").is_parent_of("end")
  end

  def test_cannot_declare_duplicate_relationship_types
    graph = Dagoba.new {
      relationship(:knows, inverse: :knows)
    }
    assert_raises("A relationship type with the name knows already exists") do
      graph.relationship(:knows, inverse: :knows)
    end
    assert_raises("A relationship type with the name knows already exists") do
      graph.relationship(:known_by, inverse: :knows)
    end
  end

  def test_cannot_use_id_as_attribute
    graph = Dagoba.new
    assert_raises(ArgumentError) { graph.add_entry("alice", {id: 1}) }
  end

  def test_requires_all_attributes_to_be_symbols
    graph = Dagoba.new
    assert_raises(ArgumentError) { graph.add_entry("alice", {"foo" => 1}) }
  end

  def test_requires_query_types_to_be_symbols
    graph = Dagoba.new
    assert_raises(ArgumentError) { graph.add_query("something") { |x| x } }
  end

  def test_requires_queries_to_be_defined_with_blocks
    graph = Dagoba.new
    assert_raises(ArgumentError) { graph.add_query(:something) }
  end

  def test_returns_empty_when_node_has_no_relations_of_given_type
    graph = Dagoba.new {
      relationship(:knows, inverse: :knows)
      add_entry("start")
    }
    assert_empty(graph.find("start").knows.run)
  end

  def test_returns_correct_results_when_node_has_relations_of_given_type
    graph = Dagoba.new {
      relationship(:knows, inverse: :knows)
      add_entry("start")
      add_entry("end")
      establish("start").knows("start")
      establish("start").knows("end")
    }
    assert_query_matches(
      graph.find("start").knows,
      [{id: "end"}, {id: "start"}]
    )
  end

  def test_allows_chaining_queries
    graph = Dagoba.new {
      relationship(:parent_of, inverse: :child_of)
      add_entry("alice")
      add_entry("bob")
      add_entry("charlie", {age: 35, education: nil})
      add_attributes("alice", {age: 45, education: "Ph.D"})
      establish("alice").parent_of("bob")
      establish("charlie").parent_of("bob")
    }
    assert_query_matches(
      graph.find("alice").parent_of.child_of,
      [
        {id: "alice", age: 45, education: "Ph.D"},
        {id: "charlie", age: 35, education: nil}
      ]
    )
  end

  def test_allows_filtering_queries
    graph = Dagoba.new {
      relationship(:parent_of, inverse: :child_of)
      add_entry("alice", {age: 40})
      add_entry("bob", {age: 12})
      add_entry("charlie", {age: 10})
      establish("alice").parent_of("bob")
      establish("alice").parent_of("charlie")
    }
    assert_query_matches(
      graph.find("alice").parent_of.where { |child| child.attributes[:age] > 10 },
      [{id: "bob", age: 12}]
    )
  end

  def test_allows_taking_vertices
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
    assert_query_matches(base_query, [{id: "emilio"}, {id: "frank"}])
    assert_query_matches(base_query, [{id: "charlie"}, {id: "daniel"}])
    assert_query_matches(base_query, [{id: "bob"}])
  end

  def test_marking_nodes_and_merging_into_single_result_set
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
    assert_query_matches(query, [{id: "alice"}, {id: "bob"}, {id: "charlie"}])
  end

  def test_allows_marking_nodes_and_excluding_from_result_set
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
    assert_query_matches(query, [{id: "charlie"}, {id: "daniel"}])
  end

  def test_allows_making_result_sets_unique
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
    assert_query_matches(
      graph.find("alice").parent_of.child_of.unique,
      [{id: "alice"}]
    )
  end

  def test_allows_selecting_results_by_attribute
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
    assert_query_matches(
      graph.find("daniel").employer_of.with_attributes({programmer: true}),
      [
        {id: "alice", programmer: true, salaried: true},
        {id: "charlie", programmer: true, salaried: false}
      ]
    )
    assert_query_matches(
      graph.find("daniel").employer_of.with_attributes({programmer: true, salaried: false}),
      [{id: "charlie", programmer: true, salaried: false}]
    )
  end

  def test_allows_selecting_attributes_in_result
    graph = Dagoba.new {
      relationship(:employee_of, inverse: :employer_of)
      add_entry("alice", {salary: 100_000})
      add_entry("bob", {salary: 70_000})
      add_entry("charlie", {salary: 1_000_000})
      establish("alice").employee_of("charlie")
      establish("bob").employee_of("charlie")
    }
    assert_query_matches(
      graph.find("charlie").employer_of.select_attributes(:salary),
      [
        {salary: 100_000},
        {salary: 70_000}
      ],
      sort_by: :salary
    )
    assert_query_matches(
      graph.find("charlie").employer_of.select_attributes(:id, :salary),
      [
        {id: "alice", salary: 100_000},
        {id: "bob", salary: 70_000}
      ]
    )
  end

  def test_allows_chaining_with_nonexistent_vertices
    graph = Dagoba.new {
      relationship(:employee_of, inverse: :employer_of)
      add_entry("alice")
    }
    assert_query_matches(graph.find("bob").employee_of, [])
  end

  def test_allows_backtracking
    graph = Dagoba.new {
      relationship(:employee_of, inverse: :employer_of)
      add_entry("alice", {programmer: true})
      add_entry("bob", {programmer: false})
      add_entry("charlie", {programmer: false})
      add_entry("daniel")
      add_entry("emilio")
      add_entry("frank")
      establish("alice").employee_of("daniel")
      establish("bob").employee_of("daniel")
      establish("charlie").employee_of("emilio")
      establish("daniel").employee_of("frank")
      establish("emilio").employee_of("frank")
    }
    query = graph.find("frank")
      .employer_of.as(:manager)
      .employer_of.with_attributes({programmer: true})
      .back(:manager)
    assert_query_matches(query, [{id: "daniel"}])
  end

  def test_evaluates_queries_correctly
    graph = Dagoba.new {
      relationship(:employee_of, inverse: :employer_of)
      add_entry("alice")
      add_entry("bob")
      add_entry("charlie")
      add_entry("daniel")
      establish("alice").employer_of("bob")
      establish("bob").employer_of("charlie")
      establish("alice").employer_of("daniel")
      add_query(:middle_managers) { |command| command.employer_of.as(:manager).employer_of.back(:manager) }
    }
    assert_query_matches(graph.find("alice").middle_managers, [{id: "bob"}])
  end

  def test_allows_redefining_queries
    graph = Dagoba.new {
      relationship(:employee_of, inverse: :employer_of)
      add_entry("alice")
      add_entry("bob")
      add_entry("charlie")
      add_entry("daniel")
      establish("alice").employer_of("bob")
      establish("bob").employer_of("charlie")
      establish("alice").employer_of("daniel")
    }
    graph.add_query(:interesting_managers) do |command|
      command.employer_of.as(:manager).employer_of.back(:manager)
    end
    assert_query_matches(
      graph.find("alice").interesting_managers,
      [{id: "bob"}]
    )
    graph.add_query(:interesting_managers) do |command|
      command.employer_of.as(:manager)
    end
    assert_query_matches(
      graph.find("alice").interesting_managers,
      [
        {id: "bob"},
        {id: "daniel"}
      ]
    )
  end

  def test_allows_second_order_queries
    graph = Dagoba.new {
      relationship(:employee_of, inverse: :employer_of)
      add_entry("alice", {title: "CTO", salary: 200_000})
      add_entry("bob", {title: "EM2", salary: 150_000})
      add_entry("charlie", {title: "SE2", salary: 90_000})
      add_entry("daniel", {title: "LSE2", salary: 120_000})
      establish("alice").employer_of("bob")
      establish("bob").employer_of("charlie")
      establish("alice").employer_of("daniel")
      add_query(:middle_managers) { |command| command.employer_of.as(:manager).employer_of.back(:manager) }
      add_query(:titles) { |command| command.select_attributes(:title) }
    }
    assert_query_matches(graph.find("alice").middle_managers.titles, [{title: "EM2"}])
  end
end
