## A requirement that requires any of the given requirements to be satisfied
class_name AnyRequirement
extends BaseRequirement


@export var requirements: Array[BaseRequirement]


func is_satisfied(game_instance: GameInstance) -> bool:
	for requirement: BaseRequirement in requirements:
		if requirement.is_satisfied(game_instance):
			return true
	return false
