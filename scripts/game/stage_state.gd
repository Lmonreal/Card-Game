extends RefCounted
class_name StageState

var deck : Array[Card]
var hand : Array[Card]
var steals_left : int = 3
var stage_score : int
var target_score : int = 300
var hand_size : int = 8

func _init() -> void:
	deck = DeckFactory.build_deck()
	deck.shuffle()
	for i in range(hand_size):
		hand.append(deck.pop_back())
