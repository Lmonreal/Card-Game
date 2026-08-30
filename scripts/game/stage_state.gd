extends RefCounted
class_name StageState

# Player Cards
var deck : Array[Card]
var hand : Array[Card]
# House Cards
var house_deck : Array[Card]
var house_hand : Array[Card]
# Game State
var steals_left : int = 2
var ladders_left : int = 4
var ladder : Array[Play]
var hand_size : int = 8
var stage_score : int
var target_score : int = 300
var last_reason : Reason = Reason.OK
var game_state : GameState
var last_ladder_score : int
var last_receipt : Array[ScoreStep]
var next_opener : Play.Who = Play.Who.HOUSE
# Enums and Constants
enum Reason {OK, MIXED_RANKS, TOO_LOW, WRONG_COUNT, EMPTY}
enum Response {ANSWERED, PASSED}
enum TurnResult {REJECTED, CONTINUES, CAPPED}
enum GameState {PLAYING, WON, LOST}
# Signals

func _init() -> void:
	game_state = GameState.PLAYING
	deck = DeckFactory.build_deck("deck_1_red")
	house_deck = DeckFactory.build_deck("deck_1_black")
	deck.shuffle()
	house_deck.shuffle()
	refill_hand(hand, deck)
	refill_hand(house_hand, house_deck)
	open_ladder()
	sort_hand(hand)
	sort_hand(house_hand)

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
	var house_play : Array[Card] = _lowest_full_set(_sets_in_hand(house_hand))
	for card in house_play:
		house_hand.erase(card)
	_record_play(Play.Who.HOUSE, house_play)
	
func respond(players_play : Array[Card]) -> Response:
	for possible_set in _sets_in_hand(house_hand):
		if possible_set.size() == players_play.size() and possible_set[0].rank > players_play[0].rank :
			for card in possible_set:
				house_hand.erase(card)
			_record_play(Play.Who.HOUSE, possible_set)
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
		last_receipt = build_receipt(true)
		stage_score += last_ladder_score
		next_opener = Play.Who.PLAYER
		return TurnResult.CAPPED


func calc_ladder_score(include_house_claim : bool) -> int:
	var scored_chips : int = 0
	var scored_mult : int = 0
	var receipt : Array[ScoreStep] = build_receipt(include_house_claim)
	for score_step in receipt:
		scored_chips += score_step.chips
		scored_mult += score_step.mult
	
	var ladder_score : int = scored_chips * scored_mult
	if hand.is_empty():
		ladder_score = ladder_score * 2
	return ladder_score


func fold(is_stealing : bool) -> void:
	if is_stealing and steals_left > 0:
		last_ladder_score = calc_ladder_score(false)
		last_receipt = build_receipt(false)
		hand.append_array(get_set_in_play())
		stage_score += last_ladder_score
		steals_left -= 1
	else:
		last_ladder_score = 0
		last_receipt.clear()
	next_opener = Play.Who.HOUSE


func _end_ladder():
	ladder.clear()
	last_receipt.clear()
	ladders_left -= 1
	refill_hand(hand, deck)
	refill_hand(house_hand, house_deck)
	sort_hand(hand)
	sort_hand(house_hand)
	if stage_score >= target_score:
		stage_won()
	elif ladders_left <= 0:
		game_over()
	elif next_opener == Play.Who.HOUSE:
		open_ladder()


func refill_hand(target_hand : Array[Card], source_deck : Array[Card]):
	while target_hand.size() < hand_size and !source_deck.is_empty():
		target_hand.append(source_deck.pop_back())


func stage_won():
	game_state = GameState.WON


func game_over():
	game_state = GameState.LOST


func _rank_desc(a : Card, b : Card) -> bool:
	return a.rank > b.rank

func sort_hand(target_hand : Array[Card]) -> void :
	target_hand.sort_custom(_rank_desc)

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

func _sets_in_hand(target_hand : Array[Card]) -> Array[Array] :
	var temp_hand : Array[Card] = target_hand.duplicate()
	temp_hand.sort_custom(_rank_desc)
	temp_hand.reverse()
	var all_sets : Array[Array] = []
	var cur_set : Array[Card] = []
	if temp_hand.is_empty():
		return all_sets
	var cur_rank : int = temp_hand.get(0).rank
	for card in temp_hand:
		if card.rank != cur_rank:
			cur_rank = card.rank
			cur_set.clear()
		cur_set.append(card)
		all_sets.append(cur_set.duplicate())
	return all_sets

func _lowest_full_set(all_sets : Array[Array]) -> Array[Card] :
	if all_sets.is_empty():
		var empty : Array[Card] = []
		return empty
	var lowest_rank : int = all_sets[0][0].rank
	var candidate : Array[Card]
	for subset in all_sets:
		if subset[0].rank == lowest_rank:
			candidate = subset
		else:
			break
	return candidate

func build_receipt(include_house_claim : bool) -> Array[ScoreStep]:
	var receipt : Array[ScoreStep] = []
	for play in ladder:
		if play.who == Play.Who.HOUSE and !include_house_claim:
			#burn()
			continue
		for card in play.cards:
			var score_step = ScoreStep.new()
			score_step.card = card
			score_step.chips = card.chips
			if play.who == Play.Who.PLAYER:
				score_step.mult = card.mult
			receipt.append(score_step)
	return receipt

func finish_ladder() -> void:
	_end_ladder()
