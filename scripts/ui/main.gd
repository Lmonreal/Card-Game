extends Control

const CARD_VISUAL : PackedScene = preload("res://scenes/ui/card_visual.tscn")
@onready var hand_area: Control = $HandArea

var deck : Array[Card] = DeckFactory.build_deck()
var hand_size : int = 8

func _ready() -> void:
	deck.shuffle()
	for i in range(hand_size):
		var card_visual = CARD_VISUAL.instantiate()
		card_visual.card_data = deck[i]
		var increment : float = hand_area.size.x / hand_size
		print(increment)
		card_visual.position.x += i * increment
		
		hand_area.add_child(card_visual)
	
