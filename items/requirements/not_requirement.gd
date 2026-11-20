class_name NotRequirement
extends BaseRequirement


@export var requirement: BaseRequirement


func is_satisfied(game_instance: GameInstance) -> bool:
	return not requirement.is_satisfied(game_instance)
