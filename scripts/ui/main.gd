extends Control

const CARD_VISUAL : PackedScene = preload("res://scenes/ui/card_visual.tscn")
@onready var hand_area: Control = $HandArea
@onready var table_view: Control = %TableView
@onready var action_bar: Control = %ActionBar
@onready var hud: Control = %Hud
@onready var score_animator: Node = %ScoreAnimator
@onready var house_area: Control = $HouseArea

var stage_state : StageState = StageState.new()
var last_turn_result : StageState.TurnResult = StageState.TurnResult.CONTINUES
var selected_cards : Array[Card] = []
var hover_slot : int = -1   # slot the dragged card is currently over; -1 = none
var animating : bool = false
enum EndKind {CAP, STEAL, COLLAPSE}

func _ready() -> void:
	# Signals up: the bar announces, the coordinator decides.
	action_bar.play_pressed.connect(_on_play_button_pressed)
	action_bar.steal_pressed.connect(_on_steal_button_pressed)
	action_bar.fold_pressed.connect(_on_fold_button_pressed)
	action_bar.sort_pressed.connect(_on_sort_button_pressed)
	action_bar.reset_pressed.connect(_on_reset_button_pressed)
	score_animator.setup(table_view, hud)
	_refresh()
	
func _get_selected() -> Array[Card]:
	return selected_cards

func _on_play_button_pressed() -> void:
	if animating:
		return
	var selected_hand : Array[Card] = _get_selected().duplicate()
	last_turn_result = stage_state.play_selected(selected_hand)
	selected_cards.clear()
	if last_turn_result == StageState.TurnResult.CAPPED:
		await _end_ladder_sequence(EndKind.CAP)
	_refresh()

func _refresh() -> void:
	_draw_areas()
	_update_hud()

func _control_refresh_helper(control : Control, cards : Array[Card], clickable : bool, face_down : bool) -> void :
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
		if face_down:
			card_visual.face_down = true
		card_visual.position = _slot_position(i, cards.size(), control)
		if card_visual.card_data in selected_cards:
			card_visual.set_selected(true)
		control.add_child(card_visual)

func _slot_position(index : int, card_count : int, area : Control) -> Vector2:
	return Vector2(index * (area.size.x / card_count), 0)

func _on_steal_button_pressed() -> void:
	if animating:
		return
	var steals_before : int = stage_state.steals_left
	stage_state.fold(true)
	selected_cards.clear()
	if stage_state.steals_left < steals_before:
		await _end_ladder_sequence(EndKind.STEAL)
	else:
		# Out of steals — the brain collapsed; don't play steal drama over it.
		await _end_ladder_sequence(EndKind.COLLAPSE)
	_refresh()

func _on_fold_button_pressed() -> void:
	if animating:
		return
	stage_state.fold(false)
	selected_cards.clear()
	await _end_ladder_sequence(EndKind.COLLAPSE)
	_refresh()

func _on_reset_button_pressed() -> void:
	if animating:
		return
	stage_state = StageState.new()
	hud.sync_score(0)
	last_turn_result = StageState.TurnResult.CONTINUES
	selected_cards.clear()
	_refresh()

func _on_sort_button_pressed() -> void:
	if animating:
		return
	stage_state.sort_hand(stage_state.hand)
	_refresh()

func _draw_areas() -> void :
	_control_refresh_helper(hand_area, stage_state.hand, true, false)
	table_view.show_pile(stage_state.ladder)
	_control_refresh_helper(house_area, stage_state.house_hand, false, true)

## The coordinator reads the brain ONCE here and hands plain values to the views.
## No view ever holds stage_state.
func _update_hud() -> void:
	var playing : bool = stage_state.game_state == StageState.GameState.PLAYING
	hud.refresh({
		"target_score": stage_state.target_score,
		"steals_left": stage_state.steals_left,
		"ladders_left": stage_state.ladders_left,
		"last_ladder_score": stage_state.last_ladder_score,
		"playing": playing,
		"state_text": str(StageState.GameState.keys()[stage_state.game_state]),
		"table_empty": stage_state.get_set_in_play().is_empty(),
		"rejected": last_turn_result == StageState.TurnResult.REJECTED,
		"reason_text": str(StageState.Reason.keys()[stage_state.last_reason]),
	})
	action_bar.set_playing(playing)


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

## The two-phase turn: the brain has already scored; the pile is still on the table.
## Show it, play the drama for how the ladder ended, THEN let the brain sweep.
func _end_ladder_sequence(kind : EndKind):
	_refresh()
	animating = true
	match kind:
		EndKind.CAP:
			await score_animator.animate_cap(
				stage_state.last_receipt, stage_state.last_ladder_score, stage_state.stage_score)
		EndKind.STEAL:
			await score_animator.animate_steal(
				stage_state.ladder, stage_state.last_receipt, stage_state.last_ladder_score, stage_state.stage_score)
		EndKind.COLLAPSE:
			await score_animator.animate_collapse(stage_state.ladder)
	animating = false
	stage_state.finish_ladder()
	_refresh()
