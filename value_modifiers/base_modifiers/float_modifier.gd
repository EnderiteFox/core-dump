class_name FloatModifier
extends BaseFloatModifier


@export var value: float


func get_value(_game_instance: GameInstance, stacks: int) -> float:
	return value * stacks
