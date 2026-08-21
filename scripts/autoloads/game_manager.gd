extends Node

func _ready() -> void:
	var s := StageState.new()
	s.target_score = 99999   # keep the stage alive through all 3 ladders
	_status(s, "START")

	# ---- LADDER 1: climb until capped ----
	print("\n== LADDER 1: climb to cap ==")
	_show_table(s)
	while true:
		var play := DeckFactory.build_set(s.set_in_play[0].rank + 1, s.set_in_play.size())
		print("  I play: rank %d x%d  (chips %d)" % [play[0].rank, play.size(), s.sum_chips(play)])
		var r := s.play_selected(play)
		if r == StageState.TurnResult.CAPPED:
			print("  HOUSE PASSES -> CAPPED")
			break
		_show_table(s)
	_status(s, "after ladder 1")

	# ---- LADDER 2: one play, then STEAL ----
	print("\n== LADDER 2: play once, then steal ==")
	_show_table(s)
	var play2 := DeckFactory.build_set(s.set_in_play[0].rank + 1, s.set_in_play.size())
	print("  I play: rank %d x%d" % [play2[0].rank, play2.size()])
	s.play_selected(play2)
	_show_table(s)
	s.fold(true)
	print("  FOLD (steal)")
	_status(s, "after ladder 2")

	# ---- LADDER 3: collapse immediately ----
	print("\n== LADDER 3: collapse ==")
	_show_table(s)
	s.fold(false)
	print("  FOLD (collapse)")
	_status(s, "after ladder 3")


func _show_table(s: StageState) -> void:
	print("  HOUSE table: rank %d x%d  (chips %d)" % [s.set_in_play[0].rank, s.set_in_play.size(), s.sum_chips(s.set_in_play)])

func _status(s: StageState, label: String) -> void:
	print("[%s] score=%d steals=%d ladders=%d hand=%d state=%s" % [
		label, s.stage_score, s.steals_left, s.ladders_left, s.hand.size(),
		StageState.GameState.keys()[s.game_state]])
