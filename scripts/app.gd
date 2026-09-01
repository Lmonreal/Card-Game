extends Control
## App — the root scene. Holds the ScreenContainer and nothing else that belongs
## to a single screen. Persistent backdrop layers (whatever the art direction
## decides) go here, above ScreenContainer in the tree, so they outlive screens.

@onready var screen_container: Control = %ScreenContainer


func _ready() -> void:
	GameManager.register_container(screen_container)
	GameManager.start_run()
