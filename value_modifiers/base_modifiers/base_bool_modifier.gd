@abstract
class_name BaseBoolModifier
extends BaseModifier


@export var bool_value_id: BoolValueId
@export var effect: EffectType


@abstract
func get_value(game_instance: GameInstance) -> bool


enum BoolValueId {
	PLACEHOLDER
}

enum EffectType {
	SET,
	AND,
	OR,
	XOR
}
