class_name Card
extends Resource

enum Suit {HEART, DIAMOND, SPADE, CLUB}


@export var name : String = "Unnamed"
@export var suit : Suit
@export var rank : int
@export var chips : int
@export var mult : int
@export var front : Texture2D
@export var back : Texture2D
