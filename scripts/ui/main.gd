extends Control

const CARD_VISUAL : PackedScene = preload("res://scenes/ui/card_visual.tscn")
@onready var hand_area: Control = $HandArea
@onready var table_area: Control = $TableArea
@onready var action_bar: Control = %ActionBar
@onready var hud: Control = %Hud
@onready var house_area: Control = $HouseArea

var stage_state : StageState = StageState.new()
var last_turn_result : StageState.TurnResult = StageState.TurnResult.CONTINUES
var selected_cards : Array[Card] = []
var hover_slot : int = -1   # slot the dragged card is currently over; -1 = none
var animating : bool = false
var score_beat : float = 0.50    # pause between count-up steps
var score_hold : float = 0.4     # pause before/after the final total reveal
enum EndKind {CAP, STEAL, COLLAPSE}

func _ready() -> void:
	# Signals up: the bar announces, the coordinator decides.
	action_bar.play_pressed.connect(_on_play_button_pressed)
	action_bar.steal_pressed.connect(_on_steal_button_pressed)
	action_bar.fold_pressed.connect(_on_fold_button_pressed)
	action_bar.sort_pressed.connect(_on_sort_button_pressed)
	action_bar.reset_pressed.connect(_on_reset_button_pressed)
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
	_draw_table_pile()
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

func _draw_table_pile():
	for child in table_area.get_children():
		child.queue_free()
	var step : int = 32
	for j in range(stage_state.ladder.size()):
		var play : Play = stage_state.ladder[j]
		for i in range(play.cards.size()):
			var card_visual = CARD_VISUAL.instantiate()
			card_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
			card_visual.card_data = play.cards[i]
			var card_pitch : float = 39 * card_visual.card_scale * 0.20
			card_visual.position = Vector2(i * card_pitch, (step) * j)
			table_area.add_child(card_visual)

func _animate_ladder_score() -> void:
	var reverse_receipt = stage_state.last_receipt.duplicate()
	reverse_receipt.reverse()
	var chips_total : int = 0
	var mult_total : int = 0
	for step in reverse_receipt:
		var visual := _find_table_visual(step.card)
		if visual:
			visual.pivot_offset = visual.size / 2
			# Beat 1: chips. Every card has these.
			_animate_card_score(visual)
			_spawn_float_label("+%d" % step.chips, visual.position, Color(0.5, 0.8, 1.0))
			chips_total += step.chips
			hud.set_tally("%d × %d" % [chips_total, mult_total])
			await get_tree().create_timer(score_beat).timeout
			# Beat 2: mult, only if this card gives any. Future add-ons = more beats here.
			if step.mult > 0:
				_animate_card_score(visual)
				_spawn_float_label("+%d" % step.mult, visual.position, Color(1.0, 0.35, 0.3))
				mult_total += step.mult
				hud.set_tally("%d × %d" % [chips_total, mult_total])
				await get_tree().create_timer(score_beat).timeout
			visual.queue_free()
	# Finale: hold, then reveal the product (Going Out shows as more than the product).
	await get_tree().create_timer(score_hold).timeout
	var product : int = chips_total * mult_total
	if stage_state.last_ladder_score > product:
		hud.set_tally("%d × %d ×2 = +%d" % [chips_total, mult_total, stage_state.last_ladder_score])
	else:
		hud.set_tally("%d × %d = +%d" % [chips_total, mult_total, stage_state.last_ladder_score])
	hud.sync_score(stage_state.stage_score)
	await get_tree().create_timer(score_hold).timeout

func _spawn_float_label(label_text : String, at : Vector2, text_color : Color = Color.WHITE) -> void:
	var fl := Label.new()
	fl.text = label_text
	fl.add_theme_font_override("font", load("res://assets/fonts/Logic_Loop.ttf"))
	fl.add_theme_font_size_override("font_size", 36)
	fl.add_theme_color_override("font_color", text_color)
	fl.add_theme_color_override("font_outline_color", Color.BLACK)
	fl.add_theme_constant_override("outline_size", 16)
	fl.position = at + Vector2(20, -10)
	table_area.add_child(fl)
	var t := create_tween().set_parallel(true)
	t.tween_property(fl, "position:y", fl.position.y - 40, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_property(fl, "modulate:a", 0.0, 0.4)
	t.chain().tween_callback(fl.queue_free)

func _find_table_visual(card : Card) -> Control:
	for child in table_area.get_children():
		if child.is_queued_for_deletion():
			continue
		if child.card_data == card:
			return child
	return null

func _animate_card_score(visual : TextureRect) -> void :
	var t := create_tween().parallel()
	t.tween_property(visual, "scale", Vector2(1.60, 1.60), 0.05).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_property(visual, "rotation_degrees", 10, 0.06).set_trans(Tween.TRANS_CUBIC)
	t.tween_property(visual, "scale", Vector2.ONE, 0.1).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	t.tween_property(visual, "rotation_degrees", 0, 0.03).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _animate_steal():
	var back : Play = stage_state.ladder.back()
	for play in stage_state.ladder:
		if play != back:
			if play.who == Play.Who.HOUSE:
				for card in play.cards:
					var visual = _find_table_visual(card)
					if visual:
						var tween : Tween = create_tween()
						tween.tween_property(visual, "modulate", Color(0,0,0,0), 0.3).set_trans(Tween.TRANS_CUBIC)
		else:
			for card in play.cards:
				var visual = _find_table_visual(card)
				if visual:
					visual.queue_free()
			await get_tree().create_timer(score_beat).timeout
	await get_tree().create_timer(0.2).timeout
	await _animate_ladder_score()

func _animate_collapse():
	for play in stage_state.ladder:
		for card in play.cards:
			var visual = _find_table_visual(card)
			if visual:
				var tween : Tween = create_tween()
				tween.tween_property(visual, "modulate", Color(0,0,0,0), 0.3)
	await get_tree().create_timer(0.2).timeout

func _end_ladder_sequence(kind : EndKind):
	_refresh()
	animating = true
	match kind:
		EndKind.CAP:
			await _animate_ladder_score()
		EndKind.STEAL:
			await _animate_steal()
		EndKind.COLLAPSE:
			await _animate_collapse()
	animating = false
	stage_state.finish_ladder()
	_refresh()
