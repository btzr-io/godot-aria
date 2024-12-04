extends VBoxContainer

func _ready() -> void:
	visibility_changed.connect(handle_visibility_changed)
	# Listen for buttons interactions:
	for button : Button in get_children():
		button.mouse_entered.connect(handle_hover.bindv([button]))
		button.focus_entered.connect(handle_focus.bindv([button]))
		button.pressed.connect(handle_pressed.bindv([button]))
	# Initial message:
	GodotARIA.notify_screen_reader("Hello! this is a test for screen readers. Press tab to open a menu.")
	
func handle_visibility_changed():
	get_children()[0].grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("continue"):
		show()

func handle_hover(button: Button):
	button.grab_focus()

func handle_focus(button: Button):
	GodotARIA.notify_screen_reader(button.text)
	
func handle_pressed(button: Button):
	GodotARIA.notify_screen_reader("You selected: " + button.text )
