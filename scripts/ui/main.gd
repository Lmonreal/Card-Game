extends Control

const CARD_VISUAL : PackedScene = preload("res://scenes/ui/card_visual.tscn")
@onready var hand_area: Control = $HandArea

var stage_state : StageState = StageState.new()



func _ready() -> void:
	var increment : float = hand_area.size.x / stage_state.hand_size
	for i in range(stage_state.hand_size):
		var card_visual = CARD_VISUAL.instantiate()
		card_visual.card_data = stage_state.hand[i]
		card_visual.position.x += i * increment
		hand_area.add_child(card_visual)
	
