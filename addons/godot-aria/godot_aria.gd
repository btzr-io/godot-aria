extends Node

# Global javascript interface:
# Accessible from window.GODOT_ARIA_PROXY on the browser.
var aria_proxy : JavaScriptObject = JavaScriptBridge.get_interface("GODOT_ARIA_PROXY")

# Print debug messages
var debug: bool = true

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

func notify_screen_reader(message):
	if OS.has_feature("web") and aria_proxy != null:
		aria_proxy.update_aria_live(str(message))
	
