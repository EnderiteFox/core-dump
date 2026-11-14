class_name ValueModifierManager
extends Node
## Manages the application of value modifiers, as well as querying the values


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


func _get_modifiers_from_instance_array(
		array: Array[ItemInstance],
		data_getter: Callable,
		desc: String
) -> Array[BaseModifier]:
	var modifiers: Array[BaseModifier] = []
	for instance: ItemInstance in array:
		var data: ItemData = data_getter.call(instance.id)
		if data == null:
			push_error("Can't read modifiers from ", desc, " ", instance.id, " with unknown data")
			continue
		modifiers.append_array(data.value_modifiers)
	return modifiers


func _get_all_modifiers() -> Array[BaseModifier]:
	var modifiers: Array[BaseModifier] = []
	modifiers.append_array(
			_get_modifiers_from_instance_array(
					item_manager.get_upgrades(),
					ItemDataManager.get_upgrade_data,
					"upgrade"
			)
	)
	modifiers.append_array(
			_get_modifiers_from_instance_array(
					item_manager.get_corruptions(),
					ItemDataManager.get_corruption_data,
					"corruption"
			)
	)
	modifiers.append_array(
			_get_modifiers_from_instance_array(
					item_manager.get_enemies(),
					ItemDataManager.get_enemy_data,
					"enemy"
			)
	)
	modifiers.append_array(_registered_modifiers)
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
	var all_modifiers: Array[BaseModifier] = _get_all_modifiers()
	var bool_modifiers: Array[BoolModifier] = all_modifiers.filter(
			func(modifier: BaseModifier) -> bool:
				return modifier is BoolModifier
	)
	bool_modifiers.filter(
			func(modifier: BoolModifier) -> bool:
				return modifier.bool_value_id == bool_value_id
	)
	
	var value: bool = _bool_value_defaults.get(bool_value_id, false)
	for modifier: BoolModifier in bool_modifiers:
		match modifier.effect:
			BoolModifier.EffectType.SET:
				value = modifier.value
			BoolModifier.EffectType.AND:
				value = value and modifier.value
			BoolModifier.EffectType.OR:
				value = value or modifier.value
			BoolModifier.EffectType.XOR:
				value = (not value) or (not modifier.value)
	return value


## Returns a float value after applying modifiers
func get_float_value(float_value_id: FloatModifier.FloatValueId) -> float:
	var all_modifiers: Array[BaseModifier] = _get_all_modifiers()
	var float_modifiers: Array[FloatModifier] = all_modifiers.filter(
			func(modifier: BaseModifier) -> bool:
				return modifier is FloatModifier
	)
	float_modifiers.filter(
			func(modifier: FloatModifier) -> bool:
				return modifier.float_value_id == float_value_id
	)
	
	var value: float = _float_value_defaults.get(float_value_id, 0.0)
	var multiplier: float = 1.0
	var global_multiplier: float = 1.0
	for modifier: FloatModifier in float_modifiers:
		match modifier.effect:
			FloatModifier.EffectType.SET:
				value = modifier.value
			FloatModifier.EffectType.ADD:
				value += modifier.value
			FloatModifier.EffectType.ADD_MULTIPLIER:
				multiplier += modifier.value
			FloatModifier.EffectType.GLOBAL_MULTIPLY:
				global_multiplier *= modifier.value
	return value * multiplier * global_multiplier
