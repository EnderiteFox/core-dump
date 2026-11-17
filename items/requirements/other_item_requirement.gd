## A requirement that requires another item to be present, with at least the given amount of stacks[br]
## The required stack count defaults to 1
class_name OtherItemRequirement
extends BaseRequirement


@export var item_category: ItemData.Category
@export var item_id: StringName
@export var needed_stacks: int = 1
@export var included_items := Included.PERMANENT


func is_satisfied(game_instance: GameInstance) -> bool:
	var include_permanent: bool = included_items in [Included.PERMANENT, Included.ALL]
	var include_temporary: bool = included_items in [Included.TEMPORARY, Included.ALL]
	return game_instance.item_manager.get_item_stacks(
			item_category,
			item_id,
			include_permanent,
			include_temporary
	)


enum Included {
	PERMANENT,
	TEMPORARY,
	ALL
}
