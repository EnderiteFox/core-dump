extends Node
## A class that handles the data linked to an item id, weither it's its icon or gameplay data

const BASE_DATA_DIR: String = "res://items"
const UPGRADES_DIR: String = BASE_DATA_DIR + "/upgrades"
const CORRUPTIONS_DIR: String = BASE_DATA_DIR + "/corruptions"
const ENEMIES_DIR: String = BASE_DATA_DIR + "/enemies"


var _item_data: Dictionary[ItemData.Category, _ItemCategoryDataDict]


func _ready() -> void:
	print("Loading upgrades...")
	_load_data_dict(ItemData.Category.UPGRADE, UPGRADES_DIR)
	print("Loading corruptions...")
	_load_data_dict(ItemData.Category.CORRUPTION, CORRUPTIONS_DIR)
	print("Loading enemies...")
	_load_data_dict(ItemData.Category.ENEMY, ENEMIES_DIR)
	print("Item loading finished")


## Load all the item data in a directory and add it to a dictionary
func _load_data_dict(item_category: ItemData.Category, folder: String) -> void:
	var category_dict := _ItemCategoryDataDict.new()

	for path: String in ResourceLoader.list_directory(folder):
		if path.ends_with("/"):
			push_warning("Found a subfolder in item datas at ", folder, "/", path)
			continue
		
		var data = load(folder + "/" + path)
		if data is not ItemData:
			push_error("Found a non-ItemData file at ", folder, "/", path)
			continue
		
		var item_data: ItemData = data as ItemData
		_validate_item_data(item_data, folder + "/" + path)
		category_dict.data[item_data.id] = item_data
		print("Loaded item ", item_data.id)
		
	_item_data[item_category] = category_dict


## Validates preconditions in item data to prevent errors
func _validate_item_data(item_data: ItemData, path: String) -> void:
	if item_data.max_stacks >= 0 and item_data.max_selection_stacks > item_data.max_stacks:
		push_error("Item ", item_data.id, " at ", path, " has a higher selection cap than stack cap\n" +
				"Players will be able to bypass the cap")


func get_item_data(category: ItemData.Category, id: StringName) -> ItemData:
	var category_dict: _ItemCategoryDataDict = _item_data.get(category, null)
	if category_dict == null:
		push_error("Trying to get data for unloaded category: ", ItemData.Category.find_key(category))
		return null
	
	var item_data: ItemData = category_dict.data.get(id, null)
	if item_data == null:
		push_error("Trying to get data for unknown item: ", ItemData.Category.find_key(category))
		
	return item_data


class _ItemCategoryDataDict extends RefCounted:
	var data: Dictionary[StringName, ItemData] = {}
