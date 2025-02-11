extends Node2D                                                                                                                                                                                                                                                                                                                                                                                                                       
# Global javascript interface:
# Accessible from window.GODOT_ARIA_PROXY on the browser.
var aria_proxy : JavaScriptObject = JavaScriptBridge.get_interface("GODOT_ARIA_PROXY")

# Print debug messages
var debug: bool = true

# Cahce to detect updates
var last_message : String = ""
var last_message_raw : String = ""
var overlay_transform : Dictionary
var prev_overlay_transform : Dictionary = {}

# Focus managment
var focus_manager : FocusManager

# VisualViewport API
var visual_viewport : JavaScriptObject

class HTML_REF extends Object:
	var id : String
	var element : JavaScriptObject
	# Constructor
	func _init(element_id : String, tag : String = "div",  props : Dictionary = {}, layer = "overlay", parent_element = null):
		var initProps : JavaScriptObject = GODOT_ARIA_UTILS.dictionary_to_js(props)
		id = element_id
		element = GodotARIA.aria_proxy.create_element_reference(tag, id, initProps, layer, parent_element)
	# Destructor
	func _notification(what: int) -> void:
		if what == NOTIFICATION_PREDELETE:
			GodotARIA.aria_proxy.remove_element_reference(id)
	# Metods
	func update_props(props : Dictionary = {}): 
		GODOT_ARIA_UTILS.dictionary_to_js(props, element)
	func update_style(styles : Dictionary = {}): 
		GODOT_ARIA_UTILS.dictionary_to_js(styles, element.style)

func _enter_tree() -> void:
	if !OS.has_feature("web"): return
	focus_manager = FocusManager.new(get_tree(), get_viewport())
	visual_viewport = JavaScriptBridge.get_interface('visualViewport')
	# Expose controls to accessibility tree
	get_tree().node_added.connect(handle_node_added)
	
func _process(delta: float) -> void:
	if !GODOT_ARIA_UTILS.is_web(): return
	overlay_transform = GODOT_ARIA_UTILS.get_viewport_css_transform(get_tree().root)
	if overlay_transform.hash() != prev_overlay_transform.hash():
		prev_overlay_transform = overlay_transform
		queue_redraw()

func _draw() -> void:
	if !overlay_transform: return
	GodotARIA.aria_proxy.sync_dom(
		overlay_transform.top,
		overlay_transform.left,
		overlay_transform.width,
		overlay_transform.height,
		overlay_transform.scale_x,
		overlay_transform.scale_y
	)
	
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
		debug_log("canvas: focus")
		if aria_proxy:
			if aria_proxy.focus_enter_position == "NEXT":
				if !focus_manager.has_focus():
					focus_manager.restore_focus("START")
				else:
					focus_manager.restore_focus("NEXT")	
			elif !focus_manager.has_focus():
				focus_manager.trap_focus()
				if aria_proxy.focus_enter_position:
					focus_manager.restore_focus(aria_proxy.focus_enter_position)
				
func _input(event: InputEvent) -> void:
	if !OS.has_feature("web") or !aria_proxy: return
	if event.is_action_pressed("ui_focus_prev", true):
		if aria_proxy.focus_enter_position == "PREV":
			focus_manager.restore_focus("PREV")
			get_viewport().set_input_as_handled()
			return
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
		if aria_proxy.focus_enter_position == "NEXT":
			focus_manager.restore_focus("NEXT")
			get_viewport().set_input_as_handled()
			return
		if !focus_manager.has_focus():
			focus_manager.restore_focus("START")
			get_viewport().set_input_as_handled()
			return
		if !focus_manager.trap_next_focus:
			get_viewport().set_input_as_handled()
			get_viewport().gui_release_focus()

func handle_node_added(node: Variant):
	if node is Control:
		# Prevent exposing control to the accessibility tree
		if "aria_hidden" in node:
			if node.aria_hidden: return
		if 'aria_role' in node or AccessibilityModule.is_valid_control(node):
			var module = AccessibilityModule.new()
			node.add_child(module)
		
func _ready() -> void:
	if !OS.has_feature("web"):
		push_warning("Addon only available for web platform.")
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
	
func notify_screen_reader(message, reannounce : bool = false, lang : String = TranslationServer.get_locale()) -> void:
	if OS.has_feature("web") and aria_proxy != null:
		var format_message = parse_message(message)
		debug_log("Speak: " + format_message)
		aria_proxy.update_live_region(format_message, "polite", reannounce, lang)
		
func alert_screen_reader(message,reannounce : bool = false, lang : String = TranslationServer.get_locale()) -> void:
	if OS.has_feature("web") and aria_proxy != null:
		var format_message = parse_message(message)
		debug_log("Alert: " + str(message))
		aria_proxy.update_live_region(format_message, "assertive", reannounce, lang)

func get_media_feature(feature: String):
	if OS.has_feature("web") and aria_proxy != null and feature:
		return GodotARIA.aria_proxy.get_media_feature(feature)
	return null
