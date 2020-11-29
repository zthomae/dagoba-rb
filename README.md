# dagoba.rb

A reinterpretation of [Dagoba: an in-memory graph database](http://aosabook.org/en/500L/dagoba-an-in-memory-graph-database.html).

This project has two goals in mind:

1. Make the public API easier to read.
   Trying to understand what queries like `g.v('Thor).out().out().out().in().in().in()` were supposed to _do_ while I was reading the chapter was difficult.
   The big idea I've pursued is in using relationship types as a first-class querying construct, rather than using generic `out` and `in` querying methods.
1. Make the implementation easier to understand.
   I disagree with the choice to combine initialization and evaluation in the definitions of the pipetype functions.
   I also found it difficult to understand the code in the order it was presented because it relied on concepts that were not defined well before they were used.
   Pipetypes and gremlins are good examples -- I didn't _really_ understand what was going on until the interpreter was explained near the end of the chapter.

I've written this in Ruby because it's the language I use the most right now.
I also feel pretty comfortable (ab)using it to remove most of the syntactic noise 

## Defining a graph

Each graph is represented by an instance of the `Dagoba` class.
The constructor can take a block which will be evaluated within the context of the new instance of the class.

The `add_entry` method will add a new node to the graph.
Each node is specified by an id, and can optionally contain a set of attributes.

The `relationship` method will define a new edge type in the graph.
Each edge is directional.
Both the forward and backward edge directions are named.

The `establish` method begins a statement to join two vertices with a given edge type.

The `query` command will let you define an alias for a set of operations on a graph.

```ruby
graph = Dagoba.new do
  add_entry "alice"
  add_entry "bob", {hobbies: ["asdf", {x: 3}]}

  relationship :knows, inverse: :known_by
  relationship :parent, inverse: :is_parent_of

  establish("bob").knows("alice")
end

graph.add_entry("charlie")
graph.add_entry("delta")

graph.establish("bob").is_parent_of("charlie")
graph.establish("delta").parent("bob")
graph.establish("charlie").knows("bob")

graph.add_query(:knows_with_hobbies) { |command| command.knows.with_attributes({hobbies: ["skiing"]}) }
```

## Querying the graph

The `find` method begins constructing a statement to search the graph.
It takes the ID of the vertex to begin searching from as its only argument.
When you use the name of the relationship or query type as a method, you get the edges originating from the node you started with.
Searching methods can be chained indefinitely.
The search will not be evaluated until the `run` method is invoked.

```ruby
graph.find("bob").knows.run  # returns the node for "alice"
graph.find("bob").known_by.run  # returns the node for "charlie"
graph.find("bob").is_parent_of.run  # returns the node for "delta"
```
 
There are also a set of special searching methods:

- `where` will filter the result set based on a predicate.
- `take` will return only the first N items of a result set.
   Calling `run` multiple times will return the rest of the items in sets of N.
- `as` will mark the current vertex with a symbol.
   This allows you to reference or backtrack to it later.
   (Since the "current" vertex will change as the search is evaluated, this can eventually be applied to multiple vertices.)
- `merge` will return all of the vertices matched by a collection of mark names.
- `except` will exclude vertices matched by a mark name.
- `unique` will deduplicate a result set by vertex ID.
- `with_attributes` will filter out vertices in the result set that do not match all of a set of provided attributes.
  This is provided as a syntactic sugar, and could be implemented in terms of `where`.
- `select_attributes` will return only the given attributes when the search is run.
- `back` will move the search pointer back to a marked vertex if a search has evaluated to a positive result.
  This is useful for retreating back to a desired vertex after conditions on its relations have been satisfied.

## License

This project is licensed under the MIT license, copyright 2020 Zach Thomae.

Much of this source code is inspired by or translating code from the original [Dagoba project](https://github.com/dxnn/dagoba).
Dagoba is licensed under the [MIT license](https://github.com/dxnn/dagoba/blob/master/LICENSE), copyright 2014 Dann Toliver.
