class_name ItemManager
extends Node
## Manages the items that players currently have
## Takes care of updating the list, and emitting corresponding signals


signal upgrade_added(upgrade: ItemInstance)
signal corruption_added(upgrade: ItemInstance)
signal enemy_added(upgrade: ItemInstance)


var _upgrades: Array[ItemInstance]
var _corruptions: Array[ItemInstance]
var _enemies: Array[ItemInstance]


func _add_in_array(
		id: StringName,
		levels_left: int,
		array: Array[ItemInstance],
		desc: String,
		data_getter: Callable,
		added_signal: Signal
) -> void:
	var matching: Array[ItemInstance] = array.filter(
			func(item: ItemInstance) -> bool:
				return item.id == id and item.is_temporary() == (levels_left >= 0)
	)
	
	if matching.size() > 1:
		push_error("Multiple ", desc, " instances found when adding ", id, " (temp)" if levels_left >= 0 else "")
		return
	elif matching.size() == 1:
		if levels_left >= 0:
			# There is already a temporary instance of this item, should not happen
			# If it happens, keep the highest levels left count
			push_warning("Trying to add a second instance of temporary ", desc, " ", id)
			matching[0].levels_left = max(matching[0].levels_left, levels_left)
			matching[0].instance_changed.emit()
			return
		
		var item_data: ItemData = data_getter.call(id)

		if item_data == null:
			push_error("Trying to add ", desc, " with unknown data: ", id)
			return
		
		# Check that we can add a stack of the item
		if _get_item_total_stacks(id, array) + 1 > item_data.max_stacks:
			push_error("Tried to add ", desc, " ", id, " above its max stacks")
		
		# Add the stack to the item
		matching[0].stacks += 1
		matching[0].instance_changed.emit()
	else:
		# Create new item
		var item := ItemInstance.new(id, levels_left)
		array.append(item)
		added_signal.emit(item)
		
		
func _remove_in_array(id: StringName, temporary: bool, array: Array[ItemInstance], desc: String) -> void:
	var matching: Array[ItemInstance] = array.filter(
			func(item: ItemInstance) -> bool:
				return item.id == id and item.is_temporary() == temporary
	)
	
	if matching.size() > 1:
		push_error("Multiple ", desc, " instances found when removing ", id, " (temp)" if temporary else "")
		return
	elif matching.size() == 0:
		push_warning("Trying to remove ", desc, " ", id, " (temp)" if temporary else "", " but it was not present")
		return
	else:
		var instance: ItemInstance = matching[0]
		
		if temporary:
			# Can only have one instance of a temporary item, delete it immediately
			array.erase(instance)
			instance.instance_removed.emit()
			return
		
		# Not temporary, update stacks
		instance.stacks -= 1
		if instance.stacks <= 0:
			array.erase(instance)
			instance.instance_removed.emit()
		else:
			instance.instance_changed.emit()
			
			
func _decrement_temp_in_array(array: Array[ItemInstance]) -> void:
	for item: ItemInstance in array:
		if item.levels_left < 0:
			continue
		item.levels_left -= 1
		if item.levels_left == 0:
			array.erase(item)
			item.instance_removed.emit()
		else:
			item.instance_changed.emit()
			
		
## Returns the total stacks for the item, across temporary and permanent items	
func _get_item_total_stacks(id: StringName, array: Array[ItemInstance]) -> int:
	var stacks: int = 0
	for item: ItemInstance in array:
		if item.id == id:
			stacks += item.stacks
	return stacks


func reset() -> void:
	var _former_upgrades: Array[ItemInstance] = _upgrades.duplicate()
	_upgrades.clear()
	for upgrade: ItemInstance in _former_upgrades:
		upgrade.instance_removed.emit()

	var _former_corruptions: Array[ItemInstance] = _corruptions.duplicate()
	_corruptions.clear()
	for corruption: ItemInstance in _former_corruptions:
		corruption.instance_removed.emit()

	var _former_enemies: Array[ItemInstance] = _enemies.duplicate()
	_enemies.clear()
	for enemy: ItemInstance in _former_enemies:
		enemy.instance_removed.emit()
			
			
## Decrements the levels left for all temporary items, and removes them if they expired
func decrement_temporary_items() -> void:
	_decrement_temp_in_array(_upgrades)
	_decrement_temp_in_array(_corruptions)
	_decrement_temp_in_array(_enemies)


func get_upgrades() -> Array[ItemInstance]:
	return _upgrades


@rpc("authority", "call_local", "reliable")
func add_upgrade(id: StringName, levels_left: int = -1) -> void:
	_add_in_array(
			id,
			levels_left,
			_upgrades,
			"upgrade",
			ItemDataManager.get_upgrade_data,
			upgrade_added
	)


@rpc("authority", "call_local", "reliable")
func remove_upgrade(id: StringName, temporary: bool) -> void:
	_remove_in_array(id, temporary, _upgrades, "upgrade")
	
	
func get_upgrade_total_stacks(id: StringName) -> int:
	return _get_item_total_stacks(id, _upgrades)


func get_corruptions() -> Array[ItemInstance]:
	return _corruptions


@rpc("authority", "call_local", "reliable")
func add_corruption(id: StringName, levels_left: int) -> void:
	_add_in_array(
			id,
			levels_left,
			_corruptions,
			"corruption",
			ItemDataManager.get_corruption_data,
			corruption_added
	)


@rpc("authority", "call_local", "reliable")
func remove_corruption(id: StringName, temporary: bool) -> void:
	_remove_in_array(id, temporary, _corruptions, "corruption")
	
	
func get_corruption_total_stacks(id: StringName) -> int:
	return _get_item_total_stacks(id, _corruptions)


func get_enemies() -> Array[ItemInstance]:
	return _enemies


@rpc("authority", "call_local", "reliable")
func add_enemy(id: StringName, levels_left: int) -> void:
	_add_in_array(
			id,
			levels_left,
			_enemies,
			"enemy",
			ItemDataManager.get_enemy_data,
			enemy_added
	)


@rpc("authority", "call_local", "reliable")
func remove_enemy(id: StringName, temporary: bool) -> void:
	_remove_in_array(id, temporary, _enemies, "enemy")
	
	
func get_enemy_total_stacks(id: StringName) -> int:
	return _get_item_total_stacks(id, _enemies)
