class_name BoolModifier
extends BaseBoolModifier


@export var value: bool


func get_value(_game_instance: GameInstance, _stacks: int) -> bool:
	return value
