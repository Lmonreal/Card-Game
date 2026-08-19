extends Node
class_name DeckFactory

const int_rank_dict = {
	1: "ace",
	11: "jack", 
	12: "queen",
	13: "king", 
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
		for num in range(1,14):
			var card : Card = Card.new()
			card.rank = num
			card.chips = num
			card.suit = suit
			card.name = int_rank_dict.get(num, str(num)) + " of " + str(suit_string_dict.get(suit))
			var path = "res://assets/Cards/%s/%s.png" % [suit_string_dict.get(suit), int_rank_dict.get(num, str(num)) + "_of_" + str(suit_string_dict.get(suit))]
			card.art = load(path)
			deck.append(card)
	return deck
