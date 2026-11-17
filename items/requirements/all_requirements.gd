## A requirement that requires all given requirements to be satisfied
class_name AllRequirements
extends BaseRequirement


@export var requirements: Array[BaseRequirement]


func is_satisfied(game_instance: GameInstance) -> bool:
	for requirement: BaseRequirement in requirements:
		if not requirement.is_satisfied(game_instance):
			return false
	return true
