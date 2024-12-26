extends Object

class_name GODOT_ARIA_UTILS

static func get_focusable_controls(node: Node, level: int = 0, list = []):
	var _level: int = level # retains local level property
	for child in node.get_children():
		if child is Control:
			if child.is_visible_in_tree() and child.focus_mode == Control.FocusMode.FOCUS_ALL:
				# print(".".repeat(_level) + child.name)
				list.push_back(child)
			if child.get_child_count() > 0:
				get_focusable_controls(child, _level + 1, list)
