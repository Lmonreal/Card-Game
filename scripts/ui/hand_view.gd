extends Control
## HandView — the player's cards. Owns selection, drag-to-reorder and the live shift.
## Holds a COPY of the cards it was last shown; never touches game state.
## Signals up: reorder_requested(from, to). Calls down: show_hand / get_selected / clear_selection.

signal reorder_requested(from : int, to : int)

const CARD_VISUAL : PackedScene = preload("res://scenes/ui/card_visual.tscn")

var _cards : Array[Card] = []       # display order == brain's hand order
var _selected : Array[Card] = []    # survives redraws; visuals don't
var _hover_slot : int = -1          # slot the dragged card is over; -1 = none


# ---- public ----

func show_hand(cards : Array[Card]) -> void:
	_cards = cards.duplicate()
	for child in get_children():
		child.queue_free()
	for i in range(_cards.size()):
		var card_visual = CARD_VISUAL.instantiate()
		card_visual.card_dropped.connect(_on_card_dropped)
		card_visual.card_clicked.connect(_on_card_clicked)
		card_visual.card_dragged.connect(_on_card_dragged)
		card_visual.card_data = _cards[i]
		card_visual.position = _slot_position(i, _cards.size())
		if _cards[i] in _selected:
			card_visual.set_selected(true)
		add_child(card_visual)


func get_selected() -> Array[Card]:
	return _selected.duplicate()


func clear_selection() -> void:
	_selected.clear()


# ---- layout ----

func _slot_position(index : int, card_count : int) -> Vector2:
	return Vector2(index * (size.x / card_count), 0)


## Which slot a card whose top-left is at `pos` (HandView-local) would land in.
func _slot_for_position(card_visual : Control, pos : Vector2) -> int:
	var center_x : float = pos.x + card_visual.size.x / 2
	var slot_width : float = size.x / _cards.size()
	return clamp(int(center_x / slot_width), 0, _cards.size() - 1)


func _is_over_hand(pos : Vector2) -> bool:
	return Rect2(Vector2.ZERO, size).grow_individual(200, 200, 200, 0).has_point(pos)


# ---- selection ----

func _on_card_clicked(card : Card, selected : bool) -> void:
	if selected:
		_selected.append(card)
	else:
		_selected.erase(card)


# ---- drag ----

func _on_card_dragged(card_visual : Control, pos : Vector2) -> void:
	var slot : int = _slot_for_position(card_visual, pos) if _is_over_hand(pos) else -1
	if slot == _hover_slot:
		return
	_hover_slot = slot
	_shift_neighbors(card_visual, slot)


## Slide every non-dragged card to where it WOULD sit if the dragged card
## were inserted at `slot`. -1 = "not over the hand" → everyone goes home.
func _shift_neighbors(dragged : Control, slot : int) -> void:
	var preview : Array[Card] = _cards.duplicate()
	if slot >= 0:
		preview.erase(dragged.card_data)
		preview.insert(slot, dragged.card_data)
	for visual in get_children():
		if visual == dragged:
			continue
		var index : int = preview.find(visual.card_data)
		var target : Vector2 = _slot_position(index, preview.size())
		if visual.selected:
			target.y = -20
		create_tween().tween_property(visual, "position", target, 0.1).set_trans(Tween.TRANS_CUBIC)


func _on_card_dropped(card_visual : Control, drop_position : Vector2) -> void:
	_hover_slot = -1
	if _is_over_hand(drop_position):
		var to : int = _slot_for_position(card_visual, drop_position)
		var from : int = _cards.find(card_visual.card_data)
		reorder_requested.emit(from, to)   # coordinator moves the card, then redraws us
	else:
		show_hand(_cards)                  # snap back: nothing changed
