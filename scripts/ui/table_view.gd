extends Control
## TableView — draws the ladder as a pile. Pure display: no signals, no game state.
## The animator finds card visuals through find_visual() and parents float labels here.

const CARD_VISUAL : PackedScene = preload("res://scenes/ui/card_visual.tscn")

var step : int = 32   # vertical offset per play (later: the rank-column layout)


func show_pile(ladder : Array[Play]) -> void:
	clear()
	for j in range(ladder.size()):
		var play : Play = ladder[j]
		for i in range(play.cards.size()):
			var card_visual = CARD_VISUAL.instantiate()
			card_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
			card_visual.card_data = play.cards[i]
			var card_pitch : float = 39 * card_visual.card_scale * 0.20
			card_visual.position = Vector2(i * card_pitch, step * j)
			add_child(card_visual)


func clear() -> void:
	for child in get_children():
		child.queue_free()


## The LIVE visual holding this Card. Skips nodes already queued for deletion —
## a refresh and an animation can share a frame, leaving two generations in the tree.
func find_visual(card : Card) -> Control:
	for child in get_children():
		if child.is_queued_for_deletion():
			continue
		if child.get("card_data") == card:
			return child
	return null
