extends Button

@onready var progress : ProgressBar = get_parent().get_node("ProgressBar")

func _pressed() -> void:
	GodotARIA.alert_screen_reader("Action triggered!")
	progress.value = 100.0
