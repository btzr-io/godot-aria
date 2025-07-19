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

static func get_control_css_transform(control: Control, parent_control: Variant):
	var real_transform : Transform2D = control.get_global_transform_with_canvas()
	var real_scale : Vector2 = real_transform.get_scale()
	var real_position : Vector2 = real_transform.origin

	# Nested content
	if parent_control:
		var parent_transform : Transform2D = parent_control.get_global_transform_with_canvas()
		real_scale = real_scale / parent_transform.get_scale() 
		real_position =  (real_position / real_transform.get_scale()) - (parent_transform.origin / parent_transform.get_scale()) 
		
	var result = {
		"top": snapped(real_position.y, 0.001), 
		"left": snapped(real_position.x, 0.001), 
		"width": round(control.size.x), 
		"height": round(control.size.y),
		"scale_x": snapped(real_scale.x, 0.001),
		"scale_y": snapped(real_scale.y, 0.001),
		"rotation": snapped(real_transform.get_rotation(), 0.001),
		"pivot_x": control.pivot_offset.x,
		"pivot_y": control.pivot_offset.y
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

static func get_safe_autoload():
	return Engine.get_main_loop().root.get_node_or_null("GodotARIA")
