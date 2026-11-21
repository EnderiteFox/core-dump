class_name ItemTooltip
extends Control


@export var title: Label
@export var description: RichTextLabel


func set_item_info(item_category: ItemData.Category, item_data: ItemData, item_instance: ItemInstance) -> void:
	assert(item_data.id == item_instance.id)
	var base_translation_id: String = ItemData.Category.find_key(item_category).to_lower() + "." + item_data.id + "."
	
	title.text = tr(base_translation_id + "name")
	description.text = tr(base_translation_id + "description")
	
	if item_instance.levels_left >= 0:
		description.append_text("\nDisappears in " + str(item_instance.levels_left) + "level")
		if item_instance.levels_left > 1:
			description.append_text("s")
	
	var tip_text: String = tr(base_translation_id + "tip")
	if tip_text != base_translation_id + "tip":
		description.append_text("\n" + tip_text)
