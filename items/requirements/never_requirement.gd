class_name NeverRequirement
extends BaseRequirement
## A requirement that is never satisfied. Used for items that normally appear in votes.


func is_satisfied(_game_instance: GameInstance) -> bool:
	return false
