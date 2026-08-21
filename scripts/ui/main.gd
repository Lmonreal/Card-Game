extends Control

const CARD_VISUAL : PackedScene = preload("res://scenes/ui/card_visual.tscn")
@onready var hand_area: Control = $HandArea
@onready var table_area: Control = $TableArea
var stage_state : StageState = StageState.new()
var last_turn_result : StageState.TurnResult


func _ready() -> void:
	_refresh()
	
func _get_selected() -> Array[Card]:
	var result : Array[Card]
	for visual in hand_area.get_children():
		if visual.selected:
			result.append(visual.card_data)
	return result

func _on_button_pressed() -> void:
	var selected_hand : Array[Card] = _get_selected()
	last_turn_result = stage_state.play_selected(selected_hand)
	_refresh()

func _refresh() -> void:
	_control_refresh_helper(hand_area, stage_state.hand, true)
	_control_refresh_helper(table_area, stage_state.set_in_play, false)

func _control_refresh_helper(control : Control, cards : Array[Card], clickable : bool) -> void :
	for child in control.get_children():
		child.queue_free()
	for i in range(cards.size()):
		var card_visual = CARD_VISUAL.instantiate()
		if !clickable:
			card_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_visual.card_data = cards[i]
		if cards.size() > 0:
			card_visual.position.x += i * (control.size.x / cards.size())
		control.add_child(card_visual)
