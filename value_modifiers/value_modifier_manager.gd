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
	# Store the stacks for the modifier
	var modifier_stacks: Dictionary[BaseBoolModifier, int]
	
	# Item modifiers
	for category: ItemData.Category in ItemData.Category.values():
		for item: ItemInstance in item_manager.get_items(category):
			var item_data: ItemData = ItemDataManager.get_item_data(category, item.id)
			if item_data == null:
				continue
			
			for base_modifier: BaseModifier in item_data.value_modifiers:
				# Ignore non-bool modifiers
				if base_modifier is not BaseBoolModifier:
					continue
				
				var modifier: BaseBoolModifier = base_modifier
				
				# Get the modifiers for the desired id
				if modifier.bool_value_id != bool_value_id:
					continue
				
				modifier_stacks[modifier] = item.stacks
	
	# Registered modifiers
	for base_modifier: BaseModifier in _registered_modifiers:
		if base_modifier is not BaseBoolModifier:
			continue
		
		var modifier: BaseBoolModifier = base_modifier
		
		if modifier.bool_value_id != bool_value_id:
			continue
		
		# Registered modifiers always have only one stack
		modifier_stacks[modifier] = 1
	
	var value: bool = _bool_value_defaults.get(bool_value_id, false)
	
	for modifier: BaseBoolModifier in modifier_stacks.keys():
		match modifier.effect:
			BaseBoolModifier.EffectType.SET:
				value = modifier.get_value(game_instance, modifier_stacks[modifier])
			BaseBoolModifier.EffectType.AND:
				value = value and modifier.get_value(game_instance, modifier_stacks[modifier])
			BaseBoolModifier.EffectType.OR:
				value = value or modifier.get_value(game_instance, modifier_stacks[modifier])
			BaseBoolModifier.EffectType.XOR:
				value = (not value) or (not modifier.get_value(game_instance, modifier_stacks[modifier]))
	
	return value


## Returns a float value after applying modifiers
func get_float_value(float_value_id: FloatModifier.FloatValueId) -> float:
	# Store the stacks for the modifier
	var modifier_stacks: Dictionary[BaseFloatModifier, int]
	
	# Item modifiers
	for category: ItemData.Category in ItemData.Category.values():
		for item: ItemInstance in item_manager.get_items(category):
			var item_data: ItemData = ItemDataManager.get_item_data(category, item.id)
			if item_data == null:
				continue
			
			for base_modifier: BaseModifier in item_data.value_modifiers:
				# Ignore non-float modifiers
				if base_modifier is not BaseFloatModifier:
					continue
				
				var modifier: BaseFloatModifier = base_modifier
				
				# Get the modifiers for the desired id
				if modifier.float_value_id != float_value_id:
					continue
				
				modifier_stacks[modifier] = item.stacks
	
	# Registered modifiers
	for base_modifier: BaseModifier in _registered_modifiers:
		if base_modifier is not BaseFloatModifier:
			continue
		
		var modifier: BaseFloatModifier = base_modifier
		
		if modifier.float_value_id != float_value_id:
			continue
		
		# Registered modifiers always have only one stack
		modifier_stacks[modifier] = 1
	
	var value: float = _float_value_defaults.get(float_value_id, 0.0)
	var multiplier: float = 1.0
	var global_multiplier: float = 1.0
	
	for modifier: BaseFloatModifier in modifier_stacks.keys():
		match modifier.effect:
			BaseFloatModifier.EffectType.SET:
				value = modifier.get_value(game_instance, modifier_stacks[modifier])
			BaseFloatModifier.EffectType.ADD:
				value += modifier.get_value(game_instance, modifier_stacks[modifier])
			BaseFloatModifier.EffectType.ADD_MULTIPLIER:
				multiplier += modifier.get_value(game_instance, modifier_stacks[modifier])
			BaseFloatModifier.EffectType.GLOBAL_MULTIPLY:
				global_multiplier *= modifier.get_value(game_instance, modifier_stacks[modifier])
	
	return value * multiplier * global_multiplier
