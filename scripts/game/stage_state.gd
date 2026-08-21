extends RefCounted
class_name StageState

# Player Cards
var deck : Array[Card]
var hand : Array[Card]
# Game State
var steals_left : int = 3
var ladders_left : int = 3
var player_cards_this_ladder : Array[Card]
var house_cards_this_ladder : Array[Card]
var hand_size : int = 8
var stage_score : int
var target_score : int = 300
var set_in_play : Array[Card]
var last_reason : Reason
var game_state : GameState
# House Settings
var house_ceiling : int = 13 
var house_opener_rank_cap : int = 5
var house_opener_count_cap : int = 1
var house_climb_cap : int = 2
# Enums and Constants
enum Reason {OK, MIXED_RANKS, TOO_LOW, WRONG_COUNT, EMPTY}
enum Response {ANSWERED, PASSED}
enum TurnResult {REJECTED, CONTINUES, CAPPED}
enum GameState {PLAYING, WON, LOST}

func _init() -> void:
	game_state = GameState.PLAYING
	deck = DeckFactory.build_deck()
	deck.shuffle()
	for i in range(hand_size):
		hand.append(deck.pop_back())
	open_ladder()

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
	house_cards_this_ladder.append_array(house_play)
	set_in_play = house_play
	
func respond(players_play : Array[Card]) -> Response:
	var response_rank = players_play[0].rank + randi_range(1, house_climb_cap)
	if response_rank <= house_ceiling:
		var response_card_count = players_play.size()
		var response : Array[Card] = DeckFactory.build_set(response_rank, response_card_count)
		house_cards_this_ladder.append_array(response)
		set_in_play = response
		return Response.ANSWERED
	return Response.PASSED
	

func play_selected(cards : Array[Card]) -> TurnResult:
	var verdict : Reason = is_valid_play(cards)
	if  verdict != Reason.OK:
		last_reason = verdict
		return TurnResult.REJECTED
	for card in cards:
		player_cards_this_ladder.append(card)
		hand.erase(card)
		
	# House responds
	var house_answer : Response = respond(cards)
	if house_answer == Response.ANSWERED:
		return TurnResult.CONTINUES
	else:
		stage_score += calc_ladder_score(true)
		_end_ladder()
		return TurnResult.CAPPED


func calc_ladder_score(include_house_claim : bool) -> int:
	var scored_chips : int = 0
	var scored_mult : int = 0
	if include_house_claim:
		scored_chips += sum_chips(house_cards_this_ladder)
	for card in player_cards_this_ladder:
		scored_chips += card.chips
		scored_mult += 1 + card.mult
	var ladder_score : int = scored_chips * scored_mult
	if hand.is_empty():
		ladder_score = ladder_score * 2
	return ladder_score


func sum_chips(cards : Array[Card]) -> int:
	var scored_chips : int = 0
	for card in cards:
		scored_chips += card.chips
	return scored_chips


func fold(is_stealing : bool) -> void:
	if is_stealing and steals_left > 0:
		hand.append_array(set_in_play)
		stage_score += calc_ladder_score(false)
		steals_left -= 1
	_end_ladder()


func _end_ladder():
	player_cards_this_ladder.clear()
	house_cards_this_ladder.clear()
	set_in_play.clear()
	ladders_left -= 1
	refill_hand()
	if stage_score >= target_score:
		stage_won()
	elif ladders_left <= 0:
		game_over()
	else:
		open_ladder()


func refill_hand():
	while hand.size() < hand_size and !deck.is_empty():
		hand.append(deck.pop_back())


func stage_won():
	game_state = GameState.WON


func game_over():
	game_state = GameState.LOST
