extends Node

func _ready() -> void:
	var state : StageState = StageState.new()
	state.open_ladder()
	print("HOUSE OPENS: rank ", state.set_in_play[0].rank, " x", state.set_in_play.size())
	while true:
		var answer_rank : int = state.set_in_play[0].rank + 1
		var my_play : Array[Card] = DeckFactory.build_set(answer_rank, state.set_in_play.size())
		print("  I ANSWER: rank ", answer_rank)
		var result := state.respond(my_play)
		if result == StageState.Response.PASSED:
			print("HOUSE PASSES — capped at rank ", answer_rank)
			break
		print("  HOUSE ANSWERS: rank ", state.set_in_play[0].rank)
