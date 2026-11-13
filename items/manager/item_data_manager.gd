extends Node
## A class that handles the data linked to an item id, weither it's its icon or gameplay data

const BASE_DATA_DIR: String = "res://items"
const UPGRADES_DIR: String = BASE_DATA_DIR + "/upgrades"
const CORRUPTIONS_DIR: String = BASE_DATA_DIR + "/corruptions"
const ENEMIES_DIR: String = BASE_DATA_DIR + "/enemies"


var _upgrade_data: Dictionary[StringName, ItemData]
var _corruption_data: Dictionary[StringName, ItemData]
var _enemy_data: Dictionary[StringName, ItemData]


func _ready() -> void:
	print("Loading upgrades...")
	_load_data_dict(_upgrade_data, UPGRADES_DIR)
	print("Loading corruptions...")
	_load_data_dict(_corruption_data, CORRUPTIONS_DIR)
	print("Loading enemies...")
	_load_data_dict(_enemy_data, ENEMIES_DIR)
	print("Item loading finished")


## Load all the item data in a directory and add it to a dictionary
func _load_data_dict(dict: Dictionary[StringName, ItemData], folder: String) -> void:
	for path: String in ResourceLoader.list_directory(folder):
		if path.ends_with("/"):
			push_warning("Found a subfolder in item datas at ", path)
			continue
		
		var data = load(path)
		if data is not ItemData:
			push_error("Found a non-ItemData file at ", path)
			continue
		
		var item_data: ItemData = data as ItemData
		_validate_item_data(item_data)
		dict[item_data.id] = item_data
		print("Loaded item ", item_data.id)
		
		
## Validates preconditions in item data to prevent errors
func _validate_item_data(item_data: ItemData) -> void:
	if item_data.max_selection_stacks > item_data.max_stacks:
		push_error("Item ", item_data.id, " has a higher selection cap than stack cap\n" +
				"Players will be able to bypass the cap")
		
		
func get_upgrade_data(id: StringName) -> ItemData:
	return _upgrade_data.get(id, null)


func get_corruption_data(id: StringName) -> ItemData:
	return _corruption_data.get(id, null)


func get_enemy_data(id: StringName) -> ItemData:
	return _enemy_data.get(id, null)
