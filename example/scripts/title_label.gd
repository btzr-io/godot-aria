extends Label

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GodotARIA.notify_screen_reader(text)
	
func _notification(what: int):
	if what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
		GodotARIA.notify_screen_reader(text)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("continue"):
		get_tree().change_scene_to_file("res://example/scenes/potions_room.tscn")
