## A requirement that requires a certain level to be reached
class_name LevelRequirement
extends BaseRequirement


@export var min_level: int = 1


func is_satisfied(game_instance: GameInstance) -> bool:
	return game_instance.current_level >= min_level
