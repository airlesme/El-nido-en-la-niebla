extends GdUnitTestSuite
## Example integration test: two objects interacting through the scene tree API,
## cleaned up via auto_free. Deterministic, no file/network I/O.


func test_add_child_registers_child_under_parent() -> void:
	# Arrange — auto_free avoids orphan nodes (gdUnit4 exit 101)
	var parent: Node = auto_free(Node.new())
	var child: Node = auto_free(Node.new())
	child.name = "Child"

	# Act
	parent.add_child(child)

	# Assert
	assert_int(parent.get_child_count()).is_equal(1)
	assert_object(parent.get_node("Child")).is_same(child)
