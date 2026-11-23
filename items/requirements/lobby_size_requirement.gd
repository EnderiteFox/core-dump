class_name LobbySizeRequirement
extends BaseRequirement


@export var player_count: int
@export var comparison: Comparison


func is_satisfied(game_instance: GameInstance) -> bool:
	match comparison:
		Comparison.LESS:
			return game_instance.get_lobby_info().max_players < player_count
		Comparison.LESS_OR_EQUAL:
			return game_instance.get_lobby_info().max_players <= player_count
		Comparison.EQUAL:
			return game_instance.get_lobby_info().max_players == player_count
		Comparison.MORE:
			return game_instance.get_lobby_info().max_players > player_count
		_:
			return game_instance.get_lobby_info().max_players >= player_count


enum Comparison {
	LESS,
	LESS_OR_EQUAL,
	EQUAL,
	MORE,
	MORE_OR_EQUAL
}
