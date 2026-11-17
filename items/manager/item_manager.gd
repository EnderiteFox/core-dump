class_name ItemManager
extends Node
## Manages the items that players currently have
## Takes care of updating the list, and emitting corresponding signals


signal item_added(category: ItemData.Category, item: ItemInstance)


var _items: Dictionary[ItemData.Category, _ItemList] = {}


func _ready() -> void:
	for category: ItemData.Category in ItemData.Category.values():
		_items[category] = _ItemList.new()


## Returns the total stacks for the item, across temporary and permanent items	
func _get_item_total_stacks(id: StringName, array: Array[ItemInstance]) -> int:
	var stacks: int = 0
	for item: ItemInstance in array:
		if item.id == id:
			stacks += item.stacks
	return stacks


func _serialize_array(array: Array[ItemInstance]) -> Array[Dictionary]:
	return array.map(
			func(item: ItemInstance) -> Dictionary:
				return item.to_dict()
	)


## Adds an item for the given category[br]
## Takes care of the creation of instances, updating stacks, checking if stacks can be incremented, and emitting signals
@rpc("authority", "call_local", "reliable")
func add_item(category: ItemData.Category, id: StringName, levels_left: int = -1) -> void:
	var item_list: _ItemList = _items[category]
	
	var matching: Array[ItemInstance] = item_list.data.filter(
			func(item: ItemInstance) -> bool:
				return item.id == id and item.is_temporary() == (levels_left >= 0)
	)
	
	if matching.size() > 1:
		push_error("Multiple ", ItemData.Category.find_key(category), " instances found when adding ", id, " (temp)" if levels_left >= 0 else "")
		return
	elif matching.size() == 1:
		if levels_left >= 0:
			# There is already a temporary instance of this item, should not happen
			# If it happens, keep the highest levels left count
			push_warning("Trying to add a second instance of temporary ", ItemData.Category.find_key(category), " ", id)
			matching[0].levels_left = max(matching[0].levels_left, levels_left)
			matching[0].instance_changed.emit()
			return
		
		var item_data: ItemData = ItemDataManager.get_item_data(category, id)

		if item_data == null:
			push_error("Trying to add ", ItemData.Category.find_key(category), " with unknown data: ", id)
			return
		
		# Check that we can add a stack of the item
		if _get_item_total_stacks(id, item_list.data) + 1 > item_data.max_stacks:
			push_error("Tried to add ", ItemData.Category.find_key(category), " ", id, " above its max stacks")
		
		# Add the stack to the item
		matching[0].stacks += 1
		matching[0].instance_changed.emit()
	else:
		# Create new item
		var item := ItemInstance.create(id, levels_left)
		item_list.data.append(item)
		item_added.emit(category, item)


## Removes an item for the given category[br]
## Takes care of decreasing stacks and removing instances when applicable
@rpc("authority", "call_local", "reliable")
func remove_item(category: ItemData.Category, id: StringName, temporary: bool) -> void:
	var item_list: _ItemList = _items[category]
	
	var matching: Array[ItemInstance] = item_list.data.filter(
			func(item: ItemInstance) -> bool:
				return item.id == id and item.is_temporary() == temporary
	)
	
	if matching.size() > 1:
		push_error("Multiple ", ItemData.Category.find_key(category), " instances found when removing ", id, " (temp)" if temporary else "")
		return
	elif matching.size() == 0:
		push_warning("Trying to remove ", ItemData.Category.find_key(category), " ", id, " (temp)" if temporary else "", " but it was not present")
		return
	else:
		var instance: ItemInstance = matching[0]
		
		if temporary:
			# Can only have one instance of a temporary item, delete it immediately
			item_list.data.erase(instance)
			instance.instance_removed.emit()
			return
		
		# Not temporary, update stacks
		instance.stacks -= 1
		if instance.stacks <= 0:
			item_list.data.erase(instance)
			instance.instance_removed.emit()
		else:
			instance.instance_changed.emit()


## Returns the current stacks for an item[br]
## Allows selecting among permanent or temporary (or both) items
func get_item_stacks(
		category: ItemData.Category,
		item_id: StringName,
		include_permanent: bool,
		include_temporary: bool
) -> int:
	if not include_permanent and not include_temporary:
		push_error("Trying to call get_item_stacks with no permanent and no temporary, result will always be 0")
		return 0
	
	var items: Array[ItemInstance] = _items[category].data.filter(
			func (item: ItemInstance) -> bool:
				return item.id == item_id
	)
	
	if not include_permanent:
		# Exclude permanent items (filter by temporary)
		items = items.filter(
				func (item: ItemInstance) -> bool:
					return item.levels_left >= 0
		)
		
	if not include_temporary:
		# Exclude temporary items (filter by permanent)
		items = items.filter(
				func (item: ItemInstance) -> bool:
					return item.levels_left < 0
		)
	
	return items.reduce(func(accum: int, item: ItemInstance) -> int: return accum + item.stacks, 0)


@rpc("authority", "call_local", "reliable")
func reset() -> void:
	for category: ItemData.Category in _items.keys():
		var item_list: _ItemList = _items[category]
		var former_items: Array[ItemInstance] = item_list.data.duplicate()
		item_list.data.clear()
		for item: ItemInstance in former_items:
			item.instance_removed.emit()


## Decrements the levels left for all temporary items, and removes them if they expired
@rpc("authority", "call_local", "reliable")
func decrement_temporary_items() -> void:
	for category: ItemData.Category in _items.keys():
		var item_list: _ItemList = _items[category]
		for item: ItemInstance in item_list.data:
			if item.levels_left < 0:
				continue
			item.levels_left -= 1
			if item.levels_left == 0:
				item_list.data.erase(item)
				item.instance_removed.emit()
			else:
				item.instance_changed.emit()


## Sets the items for a category
@rpc("authority", "call_remote", "reliable")
func set_items(category: ItemData.Category, items: Array) -> void:
	var item_list: _ItemList = _items[category]
	for item_data: Dictionary in items:
		var item := ItemInstance.from_dict(item_data)
		item_list.data.append(item)
		item_added.emit(category, item)


## Synchronizes the ItemManager state with a peer
## Only available for the server
func synchronize_with_peer(peer_id: int) -> void:
	reset.rpc_id(peer_id)
	for category: ItemData.Category in _items.keys():
		set_items.rpc_id(peer_id, category, _serialize_array(_items[category].data))


func get_items(category: ItemData.Category) -> Array[ItemInstance]:
	return _items[category].data


class _ItemList extends RefCounted:
	var data: Array[ItemInstance] = []
