extends Control
## ActionBar — the player's buttons. Knows nothing about the game.
## Buttons connect to the _on_* methods inside action_bar.tscn; those re-emit
## as named signals so the coordinator can subscribe without touching nodes.

signal play_pressed
signal steal_pressed
signal fold_pressed
signal sort_pressed
signal reset_pressed

@onready var play_button: Button = %PlayButton
@onready var steal_button: Button = %StealButton
@onready var fold_button: Button = %FoldButton
@onready var reset_button: Button = %ResetButton
@onready var sort_button: Button = %SortButton


## Called by the coordinator on every refresh. Same rules main.gd used to apply.
func set_playing(playing : bool) -> void:
	play_button.disabled = not playing
	steal_button.disabled = not playing
	fold_button.disabled = not playing
	reset_button.visible = not playing


func _on_play_button_pressed() -> void:
	play_pressed.emit()

func _on_steal_button_pressed() -> void:
	steal_pressed.emit()

func _on_fold_button_pressed() -> void:
	fold_pressed.emit()

func _on_sort_button_pressed() -> void:
	sort_pressed.emit()

func _on_reset_button_pressed() -> void:
	reset_pressed.emit()
