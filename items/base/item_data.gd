class_name ItemData
extends Resource
## The data that is linked to an item id


## The item id
@export var id: StringName
## The icon for the item
@export var icon: Texture2D
## The hard-cap on stacks[br]
## It is not possible in any way to get more stacks than this amount[br]
## -1 means no limit
@export var max_stacks: int = -1
## The maximum amount of times you can select this item in votes[br]
## When reached, the item doesn't appear in votes
@export var max_selection_stacks: int = 1
