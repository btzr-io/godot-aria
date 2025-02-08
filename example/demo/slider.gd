extends HSlider

@onready var progress = get_parent().get_node("ProgressBar")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	value_changed.connect(handle_value_changed)

func handle_value_changed(new_value):
	progress.value = new_value
