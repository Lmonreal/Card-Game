extends Node

var stage_state : StageState = StageState.new()

func _ready() -> void:
	print(stage_state.is_valid_play([DeckFactory.build_card(4,1)]))
	stage_state.set_in_play = DeckFactory.build_set(5,2)
	for i in range(2,15):
		var play : Array[Card] = DeckFactory.build_set(i,2)
		print(stage_state.is_valid_play(play))
	var wrong_count_play : Array[Card] = DeckFactory.build_set(6,1)
	var mixed_rank_play : Array[Card] = [DeckFactory.build_card(6,1), DeckFactory.build_card(8,1)]
	var empty_play : Array[Card] = []
	print(stage_state.is_valid_play(wrong_count_play))
	print(stage_state.is_valid_play(mixed_rank_play))
	print(stage_state.is_valid_play(empty_play))
