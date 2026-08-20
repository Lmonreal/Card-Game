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
var house_opener_rank_cap : int = 5
var house_opener_count_cap : int = 3
var house_climb_cap : int = 2
# Enums and Constants
enum Reason {OK, MIXED_RANKS, TOO_LOW, WRONG_COUNT, EMPTY}
enum Response {ANSWERED, PASSED}


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

func open_ladder() -> void:
	var opener_rank = randi_range(2, house_opener_rank_cap)
	var opener_card_count = randi_range(1, house_opener_count_cap)
	var house_play : Array[Card] = DeckFactory.build_set(opener_rank, opener_card_count)
	set_in_play = house_play
	
func respond(players_play : Array[Card]) -> Response:
	var response_rank = players_play[0].rank + randi_range(1, house_climb_cap)
	if response_rank <= house_ceiling:
		var response_card_count = players_play.size()
		var response : Array[Card] = DeckFactory.build_set(response_rank, response_card_count)
		set_in_play = response
		return Response.ANSWERED
	return Response.PASSED
	
