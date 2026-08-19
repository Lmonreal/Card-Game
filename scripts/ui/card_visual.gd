extends TextureRect

signal card_clicked

var card_data : Card
var selected : bool
# Defaults to false
var card_scale = 5

func _ready() -> void:
	texture = card_data.art
	size = texture.get_size() * card_scale

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		selected = !selected
		if selected == true:
			position.y -= 20
		else:
			position.y += 20
		
		card_clicked.emit()
