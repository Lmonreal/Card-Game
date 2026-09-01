extends Node
## GameManager (autoload) — the run above the stage.
## Owns RunState (what persists between screens) and the ONLY map of which
## screen comes next. Screens are leaves; this is the tree.

const TABLE_SCREEN : PackedScene = preload("res://scenes/screens/table_screen.tscn")

var run : RunState
var _container : Control    # registered by app.tscn; holds exactly one screen


func register_container(container : Control) -> void:
	_container = container


func start_run() -> void:
	run = RunState.new()
	show_screen(TABLE_SCREEN)


## Free whatever screen is showing, instantiate the next. Returns it so the
## caller can connect signals or pass config.
func show_screen(scene : PackedScene) -> Node:
	for child in _container.get_children():
		child.queue_free()
	var screen := scene.instantiate()
	_container.add_child(screen)
	return screen
