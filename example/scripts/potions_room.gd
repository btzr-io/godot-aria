extends Node2D

@onready var input = %WebTextInput
@onready var greetings = %Greetings

func _ready() -> void:
	input.on_input.connect(handle_input)
	input.on_change.connect(handle_change)

#  On enter is pressed or input exited focus
func handle_change(event: JavaScriptObject):
	var player_name = event.target.value
	if player_name and !player_name.is_empty():
		greetings.text = "Hello {x}!".format({x = player_name})
		greetings.modulate.a = 1.0
		# Read greetings
		GodotARIA.notify_screen_reader(greetings.text)

# On input value changes
func handle_input(event: JavaScriptObject):
	var player_name = event.target.value
	if !player_name or player_name.is_empty():
		greetings.modulate.a = 0.0
		GodotARIA.notify_screen_reader("")
