extends Control

const CARD_VISUAL : PackedScene = preload("res://scenes/ui/card_visual.tscn")
@onready var hand_area: Control = $HandArea

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
	for child in hand_area.get_children():
		child.queue_free()
	var increment : float = hand_area.size.x / stage_state.hand.size()
	for i in range(stage_state.hand.size()):
		var card_visual = CARD_VISUAL.instantiate()
		card_visual.card_data = stage_state.hand[i]
		card_visual.position.x += i * increment
		hand_area.add_child(card_visual)
	print(stage_state.set_in_play[0].name)
