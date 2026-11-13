class_name ItemInstance
extends Serializable
## An instance of an item, as added to players[br]
## Links an item id with instance data, like the stacks count or
## if the item is temporary, and how much time it will stay


@warning_ignore("unused_signal")
signal instance_changed
@warning_ignore("unused_signal")
signal instance_removed


var id: StringName
var levels_left: int = -1
var stacks: int = 1


static func create(p_id: StringName, p_levels_left: int = -1, p_stacks: int = 1) -> ItemInstance:
	var instance := ItemInstance.new()
	instance.id = p_id
	instance.levels_left = p_levels_left
	instance.stacks = p_stacks
	return instance
	
	
func is_temporary() -> bool:
	return levels_left >= 0
