extends PanelContainer
var message_scene = preload('./message.tscn')
@onready var input : WebTextInput = $Container/InputContainer/WebTextInput
@onready var output : ScrollContainer = $Container/Output
@onready var message_list : VBoxContainer = $Container/Output/MessageList 

var last_message

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	input.on_keydown.connect(handle_keydown)
	output.get_v_scroll_bar().changed.connect(handle_scroll)

func handle_scroll():
	await get_tree().process_frame
	if last_message:
		output.ensure_control_visible(last_message)
	
func handle_keydown(html_event: JavaScriptObject):
	if html_event.key == 'Enter':
		var input_value : String = html_event.target.value
		input_value = input_value.strip_escapes().strip_edges()
		if !input_value.is_empty():
			parse_input(input_value)
			html_event.target.value = ""

func parse_input(input_text: String):
	var command_data : Array = input_text.split(" ", false)
	if !command_data.is_empty():
		var command_name = command_data.pop_front()
		var command_args = command_data
		handle_command(command_name, command_args)
		
func handle_command(command_name, command_args):
	if command_name == "clear":
		clear_output()
		
	elif command_name == "hi":
		add_message("Hello world!")
		
	else:
		add_message("Uknown command: " + command_name)
		
func add_message(message_content: String) -> void:
	var message : PanelContainer = message_scene.instantiate()
	message.get_node("MessageContent").text = message_content
	message_list.add_child(message)
	last_message = message
	if output.focus_mode == FOCUS_NONE:
		output.focus_mode = FOCUS_ALL
	GodotARIA.focus_manager.update()
	GodotARIA.alert_screen_reader(message_content, true)
	
func clear_output():
	last_message = null
	for message in message_list.get_children():
		message.free()
	output.focus_mode = FOCUS_NONE
	GodotARIA.focus_manager.update()
	GodotARIA.alert_screen_reader("Console cleared", true)
