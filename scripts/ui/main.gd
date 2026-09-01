extends Control

const CARD_VISUAL : PackedScene = preload("res://scenes/ui/card_visual.tscn")
@onready var hand_view: Control = %HandView
@onready var table_view: Control = %TableView
@onready var action_bar: Control = %ActionBar
@onready var hud: Control = %Hud
@onready var score_animator: Node = %ScoreAnimator
@onready var house_area: Control = $HouseArea

var stage_state : StageState = StageState.new()
var last_turn_result : StageState.TurnResult = StageState.TurnResult.CONTINUES
var animating : bool = false
enum EndKind {CAP, STEAL, COLLAPSE}

func _ready() -> void:
	# Signals up: the bar announces, the coordinator decides.
	action_bar.play_pressed.connect(_on_play_button_pressed)
	action_bar.steal_pressed.connect(_on_steal_button_pressed)
	action_bar.fold_pressed.connect(_on_fold_button_pressed)
	action_bar.sort_pressed.connect(_on_sort_button_pressed)
	action_bar.reset_pressed.connect(_on_reset_button_pressed)
	hand_view.reorder_requested.connect(_on_reorder_requested)
	score_animator.setup(table_view, hud)
	_refresh()

func _on_play_button_pressed() -> void:
	if animating:
		return
	var selected_hand : Array[Card] = hand_view.get_selected()
	last_turn_result = stage_state.play_selected(selected_hand)
	hand_view.clear_selection()
	if last_turn_result == StageState.TurnResult.CAPPED:
		await _end_ladder_sequence(EndKind.CAP)
	_refresh()

func _refresh() -> void:
	_draw_areas()
	_update_hud()

## TEMP until HouseView exists: the House's face-down hand, drawn inert.
func _draw_house(cards : Array[Card]) -> void:
	for child in house_area.get_children():
		child.queue_free()
	for i in range(cards.size()):
		var card_visual = CARD_VISUAL.instantiate()
		card_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_visual.card_data = cards[i]
		card_visual.face_down = true
		card_visual.position = Vector2(i * (house_area.size.x / cards.size()), 0)
		house_area.add_child(card_visual)

func _on_steal_button_pressed() -> void:
	if animating:
		return
	var steals_before : int = stage_state.steals_left
	stage_state.fold(true)
	hand_view.clear_selection()
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
	hand_view.clear_selection()
	await _end_ladder_sequence(EndKind.COLLAPSE)
	_refresh()

func _on_reset_button_pressed() -> void:
	if animating:
		return
	stage_state = StageState.new()
	hud.sync_score(0)
	last_turn_result = StageState.TurnResult.CONTINUES
	hand_view.clear_selection()
	_refresh()

func _on_sort_button_pressed() -> void:
	if animating:
		return
	stage_state.sort_hand(stage_state.hand)
	_refresh()

func _draw_areas() -> void :
	hand_view.show_hand(stage_state.hand)
	table_view.show_pile(stage_state.ladder)
	_draw_house(stage_state.house_hand)

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


## HandView asked to move a card (drag-and-drop). The brain owns the order.
func _on_reorder_requested(from : int, to : int) -> void:
	stage_state.move_card(from, to)
	_refresh()

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
