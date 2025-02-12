extends Button

@onready var progress : ProgressBar = get_parent().get_node("ProgressBar")

@onready var accessible_node : AccessibleNode = GodotARIA.get_accessible_node(self)

func _pressed() -> void:
	GodotARIA.notify_screen_reader("Action triggered!", true)
	progress.value = 100.0
