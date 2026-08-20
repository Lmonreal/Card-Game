extends RefCounted
class_name StageState

# Player Cards
var deck : Array[Card]
var hand : Array[Card]
# Game State
var steals_left : int = 3
var hand_size : int = 8
var stage_score : int
var target_score : int = 300
var set_in_play : Array[Card]
# House Settings
var house_ceiling : int = 12 
# 
enum Reason {OK, MIXED_RANKS, TOO_LOW, WRONG_COUNT, EMPTY}

func _init() -> void:
	deck = DeckFactory.build_deck()
	deck.shuffle()
	for i in range(hand_size):
		hand.append(deck.pop_back())

func is_valid_play(played_hand : Array[Card]) -> Reason:
	if (played_hand.is_empty()):
		return Reason.EMPTY
	var played_set_rank : int = played_hand[0].rank
	for card in played_hand:
		if card.rank != played_set_rank:
			return Reason.MIXED_RANKS
	if set_in_play.size() != 0:
		if played_hand.size() != set_in_play.size():
			return Reason.WRONG_COUNT
		if played_set_rank <= set_in_play[0].rank:
			return Reason.TOO_LOW	
	return Reason.OK
