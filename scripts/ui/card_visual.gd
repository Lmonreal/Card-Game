extends TextureRect

signal card_clicked(card : Card, selec : bool)
signal card_dropped(card_visual, drop_position)
signal card_dragged(card_visual, pos)

var card_data : Card
var selected : bool
var dragging : bool
var drag_offset : Vector2
var home_pos : Vector2
var card_scale = 4
var face_down : bool
var max_tilt : float = 16.0   # degrees at the card's edge

func _ready() -> void:
	if face_down:
		texture = card_data.back
	else:
		texture = card_data.front
	size = texture.get_size() * card_scale
	mouse_exited.connect(_on_hover_end)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and not dragging:
		# Hover tilt: cursor offset from center, -1..+1 per axis, mapped to degrees.
		var n : Vector2 = (get_local_mouse_position() - size / 2) / (size / 2)
		material.set_shader_parameter("y_rot", n.x * max_tilt)
		material.set_shader_parameter("x_rot", -n.y * max_tilt)

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		home_pos = position
		drag_offset = get_parent().get_local_mouse_position() - home_pos
		dragging = true
		_on_hover_end()

func _on_hover_end() -> void:
	var tween := create_tween().set_parallel(true)
	tween.tween_property(material, "shader_parameter/y_rot", 0.0, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(material, "shader_parameter/x_rot", 0.0, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and dragging:
		position = get_parent().get_local_mouse_position() - drag_offset
		z_index = 1
		card_dragged.emit(self, position)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed and dragging:
		dragging = false
		z_index = 0
		var dist_dragged : float = (position - home_pos).length()
		if dist_dragged > 20:
			card_dropped.emit(self, position)
		else:
			position = home_pos
			set_selected(!selected)
			card_clicked.emit(card_data, selected)

func set_selected(select : bool) -> void:
	selected = select
	if select:
		position.y = -20
	else:
		position.y = 0
