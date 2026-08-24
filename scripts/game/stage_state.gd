extends RefCounted
class_name StageState

# Player Cards
var deck : Array[Card]
var hand : Array[Card]
# Game State
var steals_left : int = 3
var ladders_left : int = 4
var ladder : Array[Play]
var hand_size : int = 8
var stage_score : int
var target_score : int = 300
var last_reason : Reason = Reason.OK
var game_state : GameState
var last_ladder_score : int
# House Settings
var house_ceiling : int = 13 
var house_opener_rank_cap : int = 5
var house_opener_count_cap : int = 2
var house_climb_cap : int = 2
# Enums and Constants
enum Reason {OK, MIXED_RANKS, TOO_LOW, WRONG_COUNT, EMPTY}
enum Response {ANSWERED, PASSED}
enum TurnResult {REJECTED, CONTINUES, CAPPED}
enum GameState {PLAYING, WON, LOST}
# Signals

func _init() -> void:
	game_state = GameState.PLAYING
	deck = DeckFactory.build_deck()
	deck.shuffle()
	for i in range(hand_size):
		hand.append(deck.pop_back())
	open_ladder()
	sort_hand()

func is_valid_play(played_hand : Array[Card]) -> Reason:
	if (played_hand.is_empty()):
		return Reason.EMPTY
	var played_set_rank : int = played_hand[0].rank
	for card in played_hand:
		if card.rank != played_set_rank:
			return Reason.MIXED_RANKS
	if get_set_in_play().size() != 0:
		if played_hand.size() != get_set_in_play().size():
			return Reason.WRONG_COUNT
		if played_set_rank <= get_set_in_play()[0].rank:
			return Reason.TOO_LOW
	return Reason.OK

func open_ladder() -> void:
	var opener_rank = randi_range(2, house_opener_rank_cap)
	var opener_card_count = randi_range(1, house_opener_count_cap)
	var house_play : Array[Card] = DeckFactory.build_set(opener_rank, opener_card_count)
	_record_play(Play.Who.HOUSE, house_play)
	
func respond(players_play : Array[Card]) -> Response:
	var response_rank = players_play[0].rank + randi_range(1, house_climb_cap)
	if response_rank <= house_ceiling:
		var response_card_count = players_play.size()
		var response : Array[Card] = DeckFactory.build_set(response_rank, response_card_count)
		_record_play(Play.Who.HOUSE, response)
		return Response.ANSWERED
	return Response.PASSED
	

func play_selected(cards : Array[Card]) -> TurnResult:
	var verdict : Reason = is_valid_play(cards)
	
	if  verdict != Reason.OK:
		last_reason = verdict
		return TurnResult.REJECTED
	_record_play(Play.Who.PLAYER, cards)
	for card in cards:
		hand.erase(card)
		
	# House responds
	var house_answer : Response = respond(cards)
	if house_answer == Response.ANSWERED:
		return TurnResult.CONTINUES
	else:
		last_ladder_score = calc_ladder_score(true)
		stage_score += last_ladder_score
		_end_ladder()
		return TurnResult.CAPPED


func calc_ladder_score(include_house_claim : bool) -> int:
	var scored_chips : int = 0
	var scored_mult : int = 0
	for play in ladder:
		if play.who == Play.Who.HOUSE and include_house_claim:
			for card in play.cards:
				scored_chips += card.chips
	
		if play.who == Play.Who.PLAYER:
			for card in play.cards:
				scored_chips += card.chips
				scored_mult += 1
	var ladder_score : int = scored_chips * scored_mult
	if hand.is_empty():
		ladder_score = ladder_score * 2
	return ladder_score


func fold(is_stealing : bool) -> void:
	if is_stealing and steals_left > 0:
		last_ladder_score = calc_ladder_score(false)
		hand.append_array(get_set_in_play())
		stage_score += last_ladder_score
		steals_left -= 1
	else:
		last_ladder_score = 0
	_end_ladder()


func _end_ladder():
	ladder.clear()
	ladders_left -= 1
	refill_hand()
	sort_hand()
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


func _rank_desc(a : Card, b : Card) -> bool:
	return a.rank > b.rank

func sort_hand() -> void :
	hand.sort_custom(_rank_desc)

func move_card(from : int, to : int) -> void:
	var card : Card = hand.get(from)
	hand.remove_at(from)
	hand.insert(to, card)

func get_set_in_play() -> Array[Card] :
	if ladder.size() > 0:
		return ladder.back().cards
	var empty : Array[Card] = []
	return empty

func _record_play(who : Play.Who, cards : Array[Card]) -> void:
	var play : Play = Play.new()
	play.who = who
	play.cards = cards
	ladder.append(play)
