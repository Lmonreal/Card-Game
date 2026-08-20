extends Node
class_name DeckFactory

const int_rank_dict = {
	11: "jack", 
	12: "queen",
	13: "king", 
	14: "ace",
}

const chip_correction_dict = {
	11: 10,
	12: 10,
	13: 10,
	14: 11,
}

const suit_string_dict = {
	Card.Suit.CLUB: "clubs",
	Card.Suit.SPADE: "spades",
	Card.Suit.DIAMOND: "diamonds",
	Card.Suit.HEART: "hearts",
}

static func build_deck():
	var deck : Array[Card]
	for suit in range(0,4):
		for num in range(2,15):
			var card : Card = build_card(num, suit)
			deck.append(card)
	return deck
	
static func build_card(card_value : int, suit : int) -> Card:
	var card : Card = Card.new()
	card.rank = card_value
	card.chips = chip_correction_dict.get(card_value, card_value)
	card.suit = suit
	card.mult = 0
	card.name = int_rank_dict.get(card_value, str(card_value)) + " of " + str(suit_string_dict.get(suit))
	var path = "res://assets/Cards/%s/%s.png" % [suit_string_dict.get(suit), int_rank_dict.get(card_value, str(card_value)) + "_of_" + str(suit_string_dict.get(suit))]
	card.art = load(path)
	return card
	
static func build_set(card_rank : int, card_count : int) -> Array[Card] :
	var ladder : Array[Card]
	for i in card_count:
		var card : Card = DeckFactory.build_card(card_rank, i)
		ladder.append(card)
	return ladder
