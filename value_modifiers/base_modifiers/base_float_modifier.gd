@abstract
class_name BaseFloatModifier
extends BaseModifier


@export var float_value_id: FloatValueId
@export var effect: EffectType


@abstract
func get_value(game_instance: GameInstance, stacks: int) -> float


enum FloatValueId {
	GRAVITY
}

enum EffectType {
	SET,
	ADD,
	ADD_MULTIPLIER,
	GLOBAL_MULTIPLY
}
