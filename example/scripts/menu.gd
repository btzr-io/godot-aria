extends VBoxContainer

func _ready() -> void:
	get_viewport().gui_focus_changed.connect(handle_focus_change)
	visibility_changed.connect(handle_visibility_changed)
	# Listen for buttons interactions:
	for button : Button in get_children():
		button.mouse_entered.connect(handle_hover.bindv([button]))
		button.pressed.connect(handle_pressed.bindv([button]))

func handle_visibility_changed():
	GodotARIA.alert_screen_reader("Menu")
	await get_tree().create_timer(0.1).timeout
	get_children()[0].grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		show()

func handle_hover(button: Button):
	button.grab_focus()

func handle_focus_change(focus_control: Control):
	if focus_control is Button:
		GodotARIA.notify_screen_reader("Focus: {b}", {"b": focus_control.text})
	
func handle_pressed(button: Button):
	GodotARIA.notify_screen_reader("Selected: {button}", {"button": button.text})
