class_name BoolModifier
extends BaseModifier


@export var bool_value_id: BoolValueId
@export var value: bool:
	get=get_value
@export var effect: EffectType
	
	
func get_value() -> bool:
	return value


enum BoolValueId {
	PLACEHOLDER
}

enum EffectType {
	SET,
	AND,
	OR,
	XOR
}
