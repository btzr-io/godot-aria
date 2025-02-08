extends Button


func _pressed() -> void:
	GodotARIA.notify_screen_reader("Action triggered!")
