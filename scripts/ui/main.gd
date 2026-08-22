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

var stage_state : StageState = StageState.new()
var last_turn_result : StageState.TurnResult = StageState.TurnResult.CONTINUES


func _ready() -> void:
	_refresh()
	
func _get_selected() -> Array[Card]:
	var result : Array[Card]
	for visual in hand_area.get_children():
		if visual.selected:
			result.append(visual.card_data)
	return result

func _on_play_button_pressed() -> void:
	var selected_hand : Array[Card] = _get_selected()
	last_turn_result = stage_state.play_selected(selected_hand)
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
		if !clickable:
			card_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_visual.card_data = cards[i]
		card_visual.position.x += i * (control.size.x / cards.size())
		control.add_child(card_visual)

func _on_steal_button_pressed() -> void:
	stage_state.fold(true)
	_refresh()

func _on_fold_button_pressed() -> void:
	stage_state.fold(false)
	_refresh()

func _on_reset_button_pressed() -> void:
	stage_state = StageState.new()
	last_turn_result = StageState.TurnResult.CONTINUES
	_refresh()

func _on_sort_button_pressed() -> void:
	stage_state.sort_hand()
	_refresh()

func _draw_areas() -> void :
	_control_refresh_helper(hand_area, stage_state.hand, true)
	_control_refresh_helper(table_area, stage_state.set_in_play, false)

func _update_labels() -> void :
	stage_target.text = "%d / %d" % [stage_state.stage_score, stage_state.target_score]
	steals_left.text = str(stage_state.steals_left) + " steals left"
	ladders_left.text = str(stage_state.ladders_left) + " ladders left"
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
