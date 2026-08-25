extends Node

# --- C2 tests: the House plays from a real hand. Delete after verifying. ---
# Run and read top to bottom. What to look for is printed inline.

func _ready() -> void:
	var s := StageState.new()
	s.target_score = 99999

	print("\n=== TEST 1+3: full rally, every House play must beat mine ===")
	_show(s)
	# Climb by always answering table rank +1 at same count, until someone gives up.
	var safety := 0
	while s.game_state == StageState.GameState.PLAYING and safety < 20:
		safety += 1
		var table := s.get_set_in_play()
		if table.is_empty():
			break
		var mine := DeckFactory.build_set(table[0].rank + 1, table.size())
		if mine[0].rank > 14:
			break
		print("  I play: %s x%d" % [mine[0].rank, mine.size()])
		var r := s.play_selected(mine)
		if r == StageState.TurnResult.CAPPED:
			print("  HOUSE PASSED -> capped. (check: did its hand really have no higher set of that size?)")
			break
		_show(s)

	print("\n=== TEST 2: depletion across ladders (hand dips, refills; deck drains) ===")
	for i in range(3):
		s.fold(false)
		_show(s)

	print("\n=== TEST 1b: revenge — steal its answer, then it can't answer that rank ===")
	var table := s.get_set_in_play()
	if not table.is_empty():
		var bait := DeckFactory.build_set(table[0].rank + 1, table.size())
		print("  bait: %s x%d" % [bait[0].rank, bait.size()])
		var r := s.play_selected(bait)
		if r == StageState.TurnResult.CONTINUES:
			var loot := s.get_set_in_play()
			print("  house answered with rank %s — STEALING it" % loot[0].rank)
			s.fold(true)
			_show(s)
			print("  -> eyeball the printed hand: those exact cards must be GONE from it")
	else:
		print("  (stage ended early — reset and rerun)")

func _show(s : StageState) -> void:
	var names : Array[String] = []
	for card in s.house_hand:
		names.append(card.name)
	print("  [house: %d cards, deck %d] table: %s" % [
		s.house_hand.size(), s.house_deck.size(),
		_set_str(s.get_set_in_play())])
	print("    holds: ", ", ".join(names))

func _set_str(cards : Array[Card]) -> String:
	if cards.is_empty():
		return "(empty)"
	return "rank %d x%d" % [cards[0].rank, cards.size()]
