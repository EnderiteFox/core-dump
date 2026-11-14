class_name FloatModifier
extends BaseModifier


@export var float_value_id: FloatValueId
@export var value: float:
	get=get_value
@export var effect: EffectType


func get_value() -> float:
	return value


enum FloatValueId {
	GRAVITY
}

enum EffectType {
	SET,
	ADD,
	ADD_MULTIPLIER,
	GLOBAL_MULTIPLY
}
