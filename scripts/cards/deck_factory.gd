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

static func build_deck(back_texture : String):
	var deck : Array[Card]
	for suit in range(0,4):
		for num in range(2,15):
			var card : Card = build_card(num, suit, back_texture)
			deck.append(card)
	return deck
	
static func build_card(card_value : int, suit : int, b_texture : String) -> Card:
	var card : Card = Card.new()
	card.rank = card_value
	card.chips = chip_correction_dict.get(card_value, card_value)
	card.suit = suit
	card.mult = 1
	card.name = int_rank_dict.get(card_value, str(card_value)) + " of " + str(suit_string_dict.get(suit))
	var path = "res://assets/Cards/%s/%s.png" % [suit_string_dict.get(suit), int_rank_dict.get(card_value, str(card_value)) + "_of_" + str(suit_string_dict.get(suit))]
	var back = "res://assets/Cards/decks/" + str(b_texture) + ".png"
	card.front = load(path)
	card.back = load(back)
	return card
	
static func build_set(card_rank : int, card_count : int) -> Array[Card] :
	var ladder : Array[Card]
	for i in card_count:
		var card : Card = DeckFactory.build_card(card_rank, i % 4, "deck_6_blue")
		ladder.append(card)
	return ladder
