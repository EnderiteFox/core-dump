class_name ItemInstanceUi
extends TextureRect


const TEMPORARY_ITEM_TRANSPARENCY: float = 0.5
const item_tooltip_scene: PackedScene = preload("uid://bitex8dwkcnpd")


@export var _stack_count_label: Label

var category: ItemData.Category
var _item_data: ItemData
var _item_instance: ItemInstance
var _item_tooltip: ItemTooltip


func _ready() -> void:
	self.mouse_entered.connect(_on_mouse_entered)
	self.mouse_exited.connect(_on_mouse_exited)


func _gui_input(event: InputEvent) -> void:
	if _item_tooltip == null:
		return
	
	if event is InputEventMouseMotion:
		_item_tooltip.global_position = event.global_position


func _on_mouse_entered() -> void:
	assert(_item_tooltip == null)
	_item_tooltip = item_tooltip_scene.instantiate()
	_item_tooltip.set_item_info(category, _item_data, _item_instance)
	self.add_child(_item_tooltip)


func _on_mouse_exited() -> void:
	_item_tooltip.queue_free()
	_item_tooltip = null


func init_item(p_category: ItemData.Category, item_data: ItemData, item_instance: ItemInstance) -> void:
	self.category = p_category
	self._item_data = item_data
	if item_data.icon != null:
		self.texture = item_data.icon
	item_instance.instance_changed.connect(update_item.bind(item_instance))
	item_instance.instance_removed.connect(queue_free)
	update_item(item_instance)


func update_item(item_instance: ItemInstance) -> void:
	if item_instance.id != _item_data.id:
		push_error("Cannot update an item instance UI with a different item")
		return
	
	self._item_instance = item_instance
	
	# Set temporary items as transparent
	if item_instance.levels_left > 0:
		self.modulate.a = TEMPORARY_ITEM_TRANSPARENCY
	
	# Update stack count
	if item_instance.stacks < 2:
		_stack_count_label.text = ""
	else:
		_stack_count_label.text = str(item_instance.stacks)
