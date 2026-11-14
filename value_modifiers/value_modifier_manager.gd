class_name ValueModifierManager
extends Node
## Manages the application of value modifiers, as well as querying the values


@export var game_instance: GameInstance
@export var item_manager: ItemManager


var _registered_modifiers: Array[BaseModifier]


## Sets the defaults for boolean values[br]
## Bool values default to false
var _bool_value_defaults: Dictionary[BoolModifier.BoolValueId, bool] = {}

## Sets the defaults for float values[br]
## Float values default to 0.0
var _float_value_defaults: Dictionary[FloatModifier.FloatValueId, float] = {
	FloatModifier.FloatValueId.GRAVITY: ProjectSettings.get(&"physics/3d/default_gravity")
}


func _get_all_modifiers() -> Array[BaseModifier]:
	var modifiers: Array[BaseModifier] = []
	
	for category: ItemData.Category in ItemData.Category.values():
		var item_instances: Array[ItemInstance] = item_manager.get_items(category)
		for item: ItemInstance in item_instances:
			var data: ItemData = ItemDataManager.get_item_data(category, item.id)
			if data == null:
				continue
			modifiers.append_array(data.value_modifiers)
	
	return modifiers


## Registers a modifier that lives outside the item system
func register_modifier(modifier: BaseModifier) -> void:
	_registered_modifiers.append(modifier)


## Unregisters a registered modifier
func unregister_modifier(modifier: BaseModifier) -> void:
	_registered_modifiers.erase(modifier)


## Unregisters all registered modifiers
func reset_registered_modifiers() -> void:
	_registered_modifiers.clear()


## Returns a bool value after applying modifiers
func get_bool_value(bool_value_id: BoolModifier.BoolValueId) -> bool:
	var bool_modifiers: Array[BaseBoolModifier] = []
	for modifier: BaseModifier in _get_all_modifiers():
		if modifier is BaseBoolModifier and modifier.bool_value_id == bool_value_id:
			bool_modifiers.append(modifier)
	
	var value: bool = _bool_value_defaults.get(bool_value_id, false)
	for modifier: BaseBoolModifier in bool_modifiers:
		match modifier.effect:
			BaseBoolModifier.EffectType.SET:
				value = modifier.get_value(game_instance)
			BaseBoolModifier.EffectType.AND:
				value = value and modifier.get_value(game_instance)
			BaseBoolModifier.EffectType.OR:
				value = value or modifier.get_value(game_instance)
			BaseBoolModifier.EffectType.XOR:
				value = (not value) or (not modifier.get_value(game_instance))
	return value


## Returns a float value after applying modifiers
func get_float_value(float_value_id: FloatModifier.FloatValueId) -> float:
	var float_modifiers: Array[BaseFloatModifier] = []
	for modifier: BaseModifier in _get_all_modifiers():
		if modifier is BaseFloatModifier and modifier.float_value_id == float_value_id:
			float_modifiers.append(modifier)
	
	var value: float = _float_value_defaults.get(float_value_id, 0.0)
	var multiplier: float = 1.0
	var global_multiplier: float = 1.0
	for modifier: BaseFloatModifier in float_modifiers:
		match modifier.effect:
			BaseFloatModifier.EffectType.SET:
				value = modifier.get_value(game_instance)
			BaseFloatModifier.EffectType.ADD:
				value += modifier.get_value(game_instance)
			BaseFloatModifier.EffectType.ADD_MULTIPLIER:
				multiplier += modifier.get_value(game_instance)
			BaseFloatModifier.EffectType.GLOBAL_MULTIPLY:
				global_multiplier *= modifier.get_value(game_instance)
	return value * multiplier * global_multiplier
