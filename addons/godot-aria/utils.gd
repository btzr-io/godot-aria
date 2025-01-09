extends Object
class_name GODOT_ARIA_UTILS

static func is_web():
	return not Engine.is_editor_hint() and OS.has_feature("web")

static func to_css_color(color):
	return "#" + color.to_html(true)
	
static func dictionary_to_js(data: Dictionary, target : JavaScriptObject = null) -> JavaScriptObject:
	var result = target if target else JavaScriptBridge.create_object('Object')
	for key in data:
		result[key] = data[key]
	return result

static  func get_viewport_css_transform(canvas: Viewport) -> Dictionary:
	var t : Transform2D = canvas.get_screen_transform()
	var size : Vector2 = canvas.get_visible_rect().size
	var screen_scale : float = DisplayServer.screen_get_scale()
	var final_size_x : float = ceil(size.x * (t.x.x / screen_scale))
	var final_size_y : float = ceil(size.y * (t.y.y / screen_scale))
	var result : Dictionary = {
		top = (GodotARIA.visual_viewport.height * 0.5) - (size.y * 0.5),
		left = (GodotARIA.visual_viewport.width * 0.5) - (size.x * 0.5),
		width = ceil(size.x),
		height = ceil(size.y),
		scale_x = snapped(final_size_x / ceil(size.x), 0.001),
		scale_y = snapped(final_size_y / ceil(size.y), 0.001)
	}
	return result

static func get_control_css_transform(control: Control) -> Dictionary:
	var real_transform = control.get_global_transform_with_canvas()
	var real_scale = real_transform.get_scale()
	var real_position = real_transform.origin 
	var result = {
		top = snapped(real_position.y, 0.001), 
		left = snapped(real_position.x, 0.001), 
		width = round(control.size.x), 
		height = round(control.size.y),
		scale_x = snapped(real_scale.x, 0.001),
		scale_y = snapped(real_scale.y, 0.001),
		rotation = snapped(real_transform.get_rotation(), 0.001),
		opacity = GODOT_ARIA_UTILS.get_modulate_in_tree(control).a
	}
	return result

static func get_focusable_controls(node: Node, list = []) -> void:
	for child in node.get_children():
		if child is Control:
			if child.is_visible_in_tree() and child.focus_mode == Control.FocusMode.FOCUS_ALL:
				list.push_back(child)
		if child.get_child_count() > 0:
			get_focusable_controls(child, list)

static func get_modulate_in_tree(item: CanvasItem) -> Color:
	var container = item.get_parent()
	var modulate_in_tree : Color = item.modulate * item.self_modulate
	while container != null:
		if container is CanvasItem and not container.top_level:
			modulate_in_tree *=  container.modulate
			container = container.get_parent()
		else:
			container = null
	return modulate_in_tree
