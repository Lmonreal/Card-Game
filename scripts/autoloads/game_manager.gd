extends Node

# --- C1 test: the House owns cards. Delete after verifying. ---

func _ready() -> void:
	var s := StageState.new()
	s.target_score = 99999

	_show_house(s, "ladder 1 (fresh deal)")
	for i in range(3):
		s.fold(false)
		_show_house(s, "after collapse %d" % (i + 1))

func _show_house(s : StageState, label : String) -> void:
	var names : Array[String] = []
	for card in s.house_hand:
		names.append(card.name)
	print("[%s] house holds %d | deck %d left" % [label, s.house_hand.size(), s.house_deck.size()])
	print("   ", ", ".join(names))
