extends Node2D

# Global javascript interface:
# Accessible from window.GODOT_ARIA_PROXY on the browser.
var aria_proxy : JavaScriptObject = JavaScriptBridge.get_interface("GODOT_ARIA_PROXY")

# Focus managment
var focus_manager : FocusManager

# VisualViewport API
var visual_viewport : JavaScriptObject

# Cahce to detect updates
var overlay_transform : Dictionary
var prev_overlay_transform : Dictionary

## Settings

# Print debug messages
var debug: bool

# Enforce focus trap
var application_mode : bool :
	set(value):
		application_mode = value
		if focus_manager:
			focus_manager.update()

func _enter_tree() -> void:
	if !OS.has_feature("web"): return
	focus_manager = FocusManager.new(get_tree(), get_viewport())
	visual_viewport = JavaScriptBridge.get_interface('visualViewport')
	# Expose controls to accessibility tree
	get_tree().node_added.connect(handle_node_added)
	
func _process(delta: float) -> void:
	if !GODOT_ARIA_UTILS.is_web(): return
	overlay_transform = get_viewport_css_transform(get_tree().root)
	if overlay_transform.hash() != prev_overlay_transform.hash():
		prev_overlay_transform = overlay_transform
		queue_redraw()

func _draw() -> void:
	if !overlay_transform or !aria_proxy: return
	aria_proxy.sync_dom(
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
	
	# Restore focus with arrowkeys 
	
	if event.is_action_pressed("ui_down", true):
		if !focus_manager.has_focus():
			focus_manager.restore_focus("START")
			# Prevent default behavior
			get_viewport().set_input_as_handled()
			return
			
	if event.is_action_pressed("ui_up", true):
		if !focus_manager.has_focus():
			focus_manager.restore_focus("END")
			# Prevent default behavior
			get_viewport().set_input_as_handled()
			return
			
	# Restore focus with tab and shift + tab
	
	if event.is_action_pressed("ui_focus_prev", true):
		if !focus_manager.has_focus():
			focus_manager.restore_focus("END")
			# Prevent default behavior
			get_viewport().set_input_as_handled()
			return
		# Before exit focus
		if !application_mode and !focus_manager.trap_prev_focus:
			get_viewport().set_input_as_handled()
			get_viewport().gui_release_focus()
			
	elif event.is_action_pressed("ui_focus_next", true):
		if !focus_manager.has_focus():
			focus_manager.restore_focus("START")
			get_viewport().set_input_as_handled()
			return
		# Before exit focus
		if !application_mode and !focus_manager.trap_next_focus:
			get_viewport().set_input_as_handled()
			get_viewport().gui_release_focus()

func handle_node_added(node: Variant):
	if node is Control:
		if !focus_manager.has_focus() and node.focus_mode == Control.FOCUS_ALL:
			focus_manager.trap_focus()
		# Prevent exposing control to the accessibility tree
		if "aria_hidden" in node:
			if node.aria_hidden: return
		if 'aria_role' in node or AccessibleNode.is_valid_control(node):
			var module = AccessibleNode.new()
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

func focus_canvas() -> void:
	if OS.has_feature("web") and aria_proxy != null:
		aria_proxy.focus_canvas()

func unfocus_canvas() -> void:
	if OS.has_feature("web") and aria_proxy != null:
		aria_proxy.unfocus_canvas()
	
func notify_screen_reader(message, reannounce : bool = false, lang : String = TranslationServer.get_locale()) -> void:
	if OS.has_feature("web") and aria_proxy != null:
		var format_message : String = str(message)
		debug_log("Speak: " + format_message)
		aria_proxy.update_live_region(format_message, "polite", reannounce, lang)
		
func alert_screen_reader(message,reannounce : bool = false, lang : String = TranslationServer.get_locale()) -> void:
	if OS.has_feature("web") and aria_proxy != null:
		var format_message : String = str(message)
		debug_log("Alert: " + format_message)
		aria_proxy.update_live_region(format_message, "assertive", reannounce, lang)

func get_media_feature(feature: String):
	if OS.has_feature("web") and aria_proxy != null and feature:
		return aria_proxy.get_media_feature(feature)
	return null
	
func get_accessible_node(node : Control) -> Variant:
	if !node: return null
	for child in node.get_children():
		if child is AccessibleNode:
			return child
	return null

func get_parent_in_accesibility_tree(node: Control) -> Variant:
	if node is Control:
		var scaned : Control = node.get_parent_control()
		while scaned:
			var accessible_node = get_accessible_node(scaned)
			if accessible_node and AccessibleNode.CONTAINER_ROLES.has(accessible_node.role):
				return scaned
			scaned = scaned.get_parent_control()
	return null

func get_viewport_css_transform(canvas: Viewport) -> Dictionary:
	var t : Transform2D = canvas.get_screen_transform()
	var size : Vector2 = canvas.get_visible_rect().size
	var screen_scale : float = DisplayServer.screen_get_scale()
	var final_size_x : float = ceil(size.x * (t.x.x / screen_scale))
	var final_size_y : float = ceil(size.y * (t.y.y / screen_scale))
	var result : Dictionary = {
		top = (visual_viewport.height * 0.5) - (size.y * 0.5),
		left = (visual_viewport.width * 0.5) - (size.x * 0.5),
		width = ceil(size.x),
		height = ceil(size.y),
		scale_x = snapped(final_size_x / ceil(size.x), 0.001),
		scale_y = snapped(final_size_y / ceil(size.y), 0.001)
	}
	return result
