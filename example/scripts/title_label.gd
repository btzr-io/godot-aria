extends Label

# Called when the node enters the scene tree for the first time.
func _ready() -> void: 
	print("canvas: ready")
	GodotARIA.focus_canvas()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		GodotARIA.unfocus_canvas()
	
func _notification(what: int):
	if what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
		GodotARIA.notify_screen_reader(text)
