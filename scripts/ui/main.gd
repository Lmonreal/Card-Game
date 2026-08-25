extends Control

const CARD_VISUAL : PackedScene = preload("res://scenes/ui/card_visual.tscn")
@onready var hand_area: Control = $HandArea
@onready var table_area: Control = $TableArea
@onready var stage_target: Label = $StageTarget
@onready var steals_left: Label = $StealsLeft
@onready var ladders_left: Label = $LaddersLeft
@onready var last_reason: Label = $LastReason
@onready var message_label: Label = $MessageLabel
@onready var play_button: Button = $PlayButton
@onready var steal_button: Button = $StealButton
@onready var fold_button: Button = $FoldButton
@onready var reset_button: Button = $ResetButton
@onready var last_score: Label = $LastScore

var stage_state : StageState = StageState.new()
var last_turn_result : StageState.TurnResult = StageState.TurnResult.CONTINUES
var selected_cards : Array[Card] = []
var hover_slot : int = -1   # slot the dragged card is currently over; -1 = none


func _ready() -> void:
	_refresh()
	
func _get_selected() -> Array[Card]:
	return selected_cards

func _on_play_button_pressed() -> void:
	var selected_hand : Array[Card] = _get_selected().duplicate()
	last_turn_result = stage_state.play_selected(selected_hand)
	selected_cards.clear()
	_refresh()

func _refresh() -> void:
	_draw_areas()
	_update_labels()
	_update_visibility()

func _control_refresh_helper(control : Control, cards : Array[Card], clickable : bool) -> void :
	for child in control.get_children():
		child.queue_free()
	for i in range(cards.size()):
		var card_visual = CARD_VISUAL.instantiate()
		if clickable:
			card_visual.card_dropped.connect(_on_card_dropped)
			card_visual.card_clicked.connect(_on_card_clicked)
			card_visual.card_dragged.connect(_on_card_dragged)
		if !clickable:
			card_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_visual.card_data = cards[i]
		card_visual.position = _slot_position(i, cards.size(), control)
		if card_visual.card_data in selected_cards:
			card_visual.set_selected(true)
		control.add_child(card_visual)

func _slot_position(index : int, card_count : int, area : Control) -> Vector2:
	return Vector2(index * (area.size.x / card_count), 0)

func _on_steal_button_pressed() -> void:
	stage_state.fold(true)
	selected_cards.clear()
	_refresh()

func _on_fold_button_pressed() -> void:
	stage_state.fold(false)
	selected_cards.clear()
	_refresh()

func _on_reset_button_pressed() -> void:
	stage_state = StageState.new()
	last_turn_result = StageState.TurnResult.CONTINUES
	selected_cards.clear()
	_refresh()

func _on_sort_button_pressed() -> void:
	stage_state.sort_hand(stage_state.hand)
	_refresh()

func _draw_areas() -> void :
	_control_refresh_helper(hand_area, stage_state.hand, true)
	_control_refresh_helper(table_area, stage_state.get_set_in_play(), false)

func _update_labels() -> void :
	stage_target.text = "%d / %d" % [stage_state.stage_score, stage_state.target_score]
	steals_left.text = str(stage_state.steals_left) + " steals left"
	ladders_left.text = str(stage_state.ladders_left) + " ladders left"
	last_score.text = "+" + str(stage_state.last_ladder_score)
	if last_turn_result == StageState.TurnResult.REJECTED:
		last_reason.text = str(stage_state.Reason.keys()[stage_state.last_reason])
	else:
		last_reason.text = ""
	message_label.text = str(stage_state.GameState.keys()[stage_state.game_state])


func _update_visibility() -> void :
	var playing : bool = stage_state.game_state == StageState.GameState.PLAYING
	# Buttons
	play_button.disabled = not playing
	steal_button.disabled = not playing
	fold_button.disabled = not playing
	reset_button.visible = not playing
	# Labels
	steals_left.visible = playing
	ladders_left.visible = playing
	last_reason.visible = playing
	message_label.visible = not playing


# ---- Drag / drop ----

# Which hand slot a card at `pos` (HandArea-local, top-left) would land in.
func _slot_for_position(card_visual : Control, pos : Vector2) -> int:
	var center_x : float = pos.x + card_visual.size.x / 2
	var slot_width : float = hand_area.size.x / stage_state.hand.size()
	return clamp(int(center_x / slot_width), 0, stage_state.hand.size() - 1)

func _is_over_hand(pos : Vector2) -> bool:
	return Rect2(Vector2.ZERO, hand_area.size).grow_individual(200, 200, 200, 0).has_point(pos)

func _on_card_dragged(card_visual : Control, pos : Vector2) -> void:
	var slot : int = _slot_for_position(card_visual, pos) if _is_over_hand(pos) else -1
	if slot == hover_slot:
		return
	hover_slot = slot
	_shift_neighbors(card_visual, slot)

# Slide every non-dragged card to where it WOULD sit if the dragged card
# were inserted at `slot`. -1 = "not over the hand" → everyone goes home.
func _shift_neighbors(dragged : Control, slot : int) -> void:
	var preview : Array[Card] = stage_state.hand.duplicate()
	if slot >= 0:
		preview.erase(dragged.card_data)
		preview.insert(slot, dragged.card_data)
	for visual in hand_area.get_children():
		if visual == dragged:
			continue
		var index : int = preview.find(visual.card_data)
		var target : Vector2 = _slot_position(index, preview.size(), hand_area)
		if visual.selected:
			target.y = -20
		create_tween().tween_property(visual, "position", target, 0.1).set_trans(Tween.TRANS_CUBIC)

func _on_card_dropped(card_visual : Control, drop_position : Vector2) -> void:
	hover_slot = -1
	if _is_over_hand(drop_position):
		var to : int = _slot_for_position(card_visual, drop_position)
		var from : int = stage_state.hand.find(card_visual.card_data)
		stage_state.move_card(from, to)
	_refresh()

func _on_card_clicked(card : Card, selected : bool) -> void:
	if selected:
		selected_cards.append(card)
	else:
		selected_cards.erase(card)
