class_name ItemMenu
extends Control


const CATEGORIES_ORDER: Array[ItemData.Category] = [
	ItemData.Category.UPGRADE,
	ItemData.Category.CORRUPTION,
	ItemData.Category.ENEMY
]
const item_instance_ui_scene: PackedScene = preload("uid://b4ovtbxskcdff")


@export var player: Player
@export var item_container: Control

var item_manager: ItemManager
var count_by_category: Dictionary[ItemData.Category, int]


func _ready() -> void:
	await player.ready
	if not player.is_local:
		self.queue_free()
		return
	item_manager = player.game_instance.item_manager
	item_manager.item_added.connect(_on_new_item)


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"toggle_items"):
		self.visible = not self.visible


func _on_new_item(category: ItemData.Category, item_instance: ItemInstance) -> void:
	# Get item data
	var item_data: ItemData = ItemDataManager.get_item_data(category, item_instance.id)
	if item_data == null:
		return
	
	# Init item UI
	var item_instance_ui: ItemInstanceUi = item_instance_ui_scene.instantiate()
	item_instance_ui.init_item(category, item_data, item_instance)
	
	# Calculate the position in the menu
	# (at the end of its category, after items from previous categories)
	var index: int = 0
	var category_index: int = CATEGORIES_ORDER.find(category)
	assert(
		category_index != -1,
		"Missing category " + ItemData.Category.find_key(category) + " in CATEGORIES_ORDER"
	)
	for i: int in range(category_index + 1):
		index += count_by_category.get(CATEGORIES_ORDER[i], 0)
	
	# Increment the item count
	count_by_category[category] = count_by_category.get(category, 0) + 1
	
	# Update item count if the item is removed
	item_instance_ui.tree_exited.connect(_on_item_removed.bind(item_instance_ui))
	
	# Add child
	item_container.add_child(item_instance_ui)
	item_container.move_child(item_instance_ui, index)


func _on_item_removed(item_instance_ui: ItemInstanceUi) -> void:
	assert(count_by_category.has(item_instance_ui.category))
	assert(count_by_category[item_instance_ui.category] > 0)
	count_by_category[item_instance_ui.category] -= 1
