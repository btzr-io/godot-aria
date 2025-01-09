extends Node2D

var c = JavaScriptBridge.create_callback(_test)

# Called when the node enters the scene tree for the first time.
func read_instructions():
	GodotARIA.notify_screen_reader($Title.text + ": Use Tab or Arrow keys to explore the room, press enter or space to inspect an object. Press R to read again.")
	
func _ready() -> void:
	read_instructions()

func _test(args):
	print(args)
	
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("Read"):
		get_tree().reload_current_scene()

func _notification(what: int):
	if what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
		var focus_control = get_viewport().gui_get_focus_owner()
		if focus_control and "target" in focus_control:
			GodotARIA.notify_screen_reader("Potions room: " + focus_control.target.aria_label)
