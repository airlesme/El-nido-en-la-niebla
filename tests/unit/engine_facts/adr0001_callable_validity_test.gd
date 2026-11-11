extends GdUnitTestSuite
# Verifica NS-1 de ADR-0001 en Godot 4.7.2 (V-ENG-1).
## Callable bound to a freed node: is_valid() and the is_instance_valid(get_object()) alternative.


func test_callable_of_freed_node_is_invalid() -> void:
	# Arrange
	var node: Node = Node.new()
	var cb: Callable = Callable(node, &"get_name")
	var valid_before: bool = cb.is_valid()

	# Act
	node.free()
	var valid_after: bool = cb.is_valid()
	print("V-ENG-1 is_valid before=", valid_before, " after_free=", valid_after)

	# Assert
	assert_bool(valid_before).is_true()
	assert_bool(valid_after).is_false()


func test_freed_node_callable_object_is_not_a_valid_instance() -> void:
	# Arrange
	var node: Node = Node.new()
	var cb: Callable = Callable(node, &"get_name")

	# Act
	node.free()
	var obj: Object = cb.get_object()
	var instance_valid: bool = is_instance_valid(obj)
	print("V-ENG-1 alt get_object()==null:", obj == null, " is_instance_valid=", instance_valid)

	# Assert
	assert_bool(instance_valid).is_false()


func test_calling_callable_of_freed_node_is_guarded_by_validity_check() -> void:
	# Arrange
	var node: Node = Node.new()
	var cb: Callable = Callable(node, &"get_name")
	node.free()

	# Act: the bus guard (skip when invalid) never calls the dead callable
	var called: bool = false
	if cb.is_valid():
		cb.call()
		called = true

	# Assert
	assert_bool(called).is_false()
