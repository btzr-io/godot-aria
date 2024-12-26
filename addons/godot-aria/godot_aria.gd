extends Node

# Global javascript interface:
# Accessible from window.GODOT_ARIA_PROXY on the browser.
var aria_proxy : JavaScriptObject = JavaScriptBridge.get_interface("GODOT_ARIA_PROXY")

# Print debug messages
var debug: bool = true

# Cahce to detect updates
var last_values = {}
var last_message = ""
var last_message_raw = ""

# Focus managment
var focus_layer : CanvasLayer
var focus_layer_scene = preload("./nodes/focus_layer/node.tscn")
var focus_manager : FocusManager

func setup_focus_layer():
	focus_layer = focus_layer_scene.instantiate()
	add_child(focus_layer)

func register_focus(target: AccessibleModule) -> FocusControl:
	return focus_layer.create_focus_control(target)

func _enter_tree() -> void:
	setup_focus_layer()
	focus_manager = FocusManager.new(get_tree(), get_viewport())

func _notification(what: int):
	if what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
		debug_log("canvas: focus")
		if aria_proxy and !focus_manager.has_focus():
			focus_manager.trap_focus()
			focus_manager.restore_focus(aria_proxy.focus_enter_position)
		
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_focus_prev", true):
		if !focus_manager.has_focus():
			focus_manager.restore_focus("END")
			# Prevent default behavior
			get_viewport().set_input_as_handled()
			return
		if !focus_manager.trap_prev_focus:
			# Prevent default behavior
			get_viewport().set_input_as_handled()
			get_viewport().gui_release_focus()
	
	elif event.is_action_pressed("ui_focus_next", true):
		if !focus_manager.has_focus():
			focus_manager.restore_focus("START")
			get_viewport().set_input_as_handled()
			return
		if !focus_manager.trap_next_focus:
			get_viewport().set_input_as_handled()
			get_viewport().gui_release_focus()

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
	
func parse_message(message):
	var result : String = str(message)
	last_message = result
	last_message_raw = message
	return result

func focus_canvas() -> void:
	if OS.has_feature("web") and aria_proxy != null:
		aria_proxy.focus_canvas()

func unfocus_canvas() -> void:
	if OS.has_feature("web") and aria_proxy != null:
		aria_proxy.unfocus_canvas()
	
func notify_screen_reader(message) -> void:
	var format_message = parse_message(message)
	if OS.has_feature("web") and aria_proxy != null:
		debug_log("Speak: " + format_message)
		aria_proxy.update_aria_region(format_message)
	
func alert_screen_reader(message) -> void:
	var format_message = parse_message(message)
	if OS.has_feature("web") and aria_proxy != null:
		debug_log("Alert: " + str(message))
		aria_proxy.update_aria_region(format_message, "assertive")
