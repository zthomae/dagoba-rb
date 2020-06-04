# What I want the API to look like:
#
#   graph = Dagoba.new do
#     vertex "alice"
#     vertex "bob", hobbies: ["asdf", {x: 3}]
#
#     relationship :knows, inverse: :known_by
#     relationship :parent, inverse: :is_parent_of
#
#     establish("bob").knows("alice")
#   end
#
#   graph.vertex("charlie")
#   graph.vertex("delta")
#
#   graph.establish("bob").is_parent_of("charlie")
#   graph.establish("delta").parent("bob")
#   graph.establish("charlie").knows("bob")
#
# When you use the name of the label as a method, you get the edges originating
# from the node you started with.
#
#   graph.node("bob").knows  # returns the node for "alice"
#
# To go in the reverse order, you can either use inverse association names or
# the reverse method:
#
#   graph.node("bob").known_by  # returns the node for "charlie"
#   graph.node("bob").is_parent_of  # returns the node for "delta"
#
# If you grab multiple edges, the chained methods work in exactly the same
# way. You can define aliases to make queries look cleaner. Alias names
# cannot conflict with existing relationship or inverse names.
#
#   graph.relationship_type(:parents).means(:parent)
#   graph.relationship_type(:children).reverses(:parents)
#
#   graph.parents  # returns the nodes for "bob" and "alice"
#   graph.children  # returns the nodes for "charlie" and "bob"
class Dagoba
end
