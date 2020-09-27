# Dagoba

A reinterpretation of [Dagoba: an in-memory graph database](http://aosabook.org/en/500L/dagoba-an-in-memory-graph-database.html).

## Design Notes

What I want the API to look like:

```ruby
graph = Dagoba.new do
  add_entry "alice"
  add_entry "bob", hobbies: ["asdf", {x: 3}]

  relationship :knows, inverse: :known_by
  relationship :parent, inverse: :is_parent_of

  establish("bob").knows("alice")
end

graph.add_entry("charlie")
graph.add_entry("delta")

graph.establish("bob").is_parent_of("charlie")
graph.establish("delta").parent("bob")
graph.establish("charlie").knows("bob")
```

When you use the name of the label as a method, you get the edges originating
from the node you started with.

```ruby
graph.find("bob").knows.run  # returns the node for "alice"
```
    
To go in the reverse order, you can either use inverse association names or
the reverse method:

```ruby
graph.find("bob").known_by.run  # returns the node for "charlie"
graph.find("bob").is_parent_of.run  # returns the node for "delta"
```
    
If you grab multiple edges, the chained methods work in exactly the same
way. You can define aliases to make queries look cleaner. Alias names
cannot conflict with existing relationship or inverse names.

```ruby
graph.relationship_type(:parents).means(:parent)
graph.relationship_type(:children).reverses(:parents)

graph.parents.run  # returns the nodes for "bob" and "alice"
graph.children.run  # returns the nodes for "charlie" and "bob"
```
