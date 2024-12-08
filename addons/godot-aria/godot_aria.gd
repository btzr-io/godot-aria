extends Node

# Global javascript interface:
# Accessible from window.GODOT_ARIA_PROXY on the browser.
var focus_layer_scene = preload("./nodes/focus_layer/node.tscn")
var aria_proxy : JavaScriptObject = JavaScriptBridge.get_interface("GODOT_ARIA_PROXY")

# Print debug messages
var debug: bool = true

# Default to true for native screen reader usage:
# Set to false if you are using a custom TTS
var native_screen_reader = true

var allow_repetition = true

# Cahce to detect updates
var last_values = {}
var last_message = ""
var last_message_raw = ""

var focus_layer : CanvasLayer
	
func setup_focus_layer():
	focus_layer = focus_layer_scene.instantiate()
	add_child(focus_layer)

func register_focus_area(area: Area2D) -> FocusControl:
	return focus_layer.create_focus_control(area)


func _enter_tree() -> void:
	#get_tree().node_added.connect(handle_aria_injector)
	setup_focus_layer()

#func handle_aria_injector(n):
#	print(n)
	
func _ready() -> void:
	if !OS.has_feature("web"):
		push_error("Addon only available for web platform.")
		return
	
	if aria_proxy == null:
		printerr("Aria proxy not found. Make sure is a valid property of the JavaScript window")
		return
	
	debug_log("Godot-aria: ARIA proxy loaded.")



func debug_log(message):
	if debug: print_debug(message)

func parse_message(message, values):
	var parsed = GODOT_ARIA_UTILS.parse_message(message, values)
	var result = parsed.text
	if !values.is_empty():
		result = parsed.formated
		# Check for changes only
		var changes = []
		for value_name in parsed.values:
			if last_values.has(value_name) and values[value_name] != last_values[value_name]:
				changes.push_back(values[value_name])
		# Read changes instead of full message:
		if !changes.is_empty():
			result = ", ".join(changes)
	# Update cache
	last_values = values.duplicate()
	last_message = result
	last_message_raw = message
	return result
	
func notify_screen_reader(message, dynamic_values = {}):
	var format_message = parse_message(message, dynamic_values)
	if OS.has_feature("web") and aria_proxy != null and native_screen_reader:
		debug_log("Speak: " + format_message)
		aria_proxy.update_aria_region(format_message)
	
func alert_screen_reader(message, dynamic_values = {}):
	var format_message = parse_message(message, dynamic_values)
	if OS.has_feature("web") and aria_proxy != null and native_screen_reader:
		debug_log("Alert: " + str(message))
		aria_proxy.update_aria_region(format_message, "assertive")
