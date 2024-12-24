extends Object

class_name GODOT_ARIA_UTILS

static var regex_test = RegEx.create_from_string('\\{[^\\}{]*}')

static func get_focusable_controls(node: Node, level: int = 0, list = []):
	var _level: int = level # retains local level property
	for child in node.get_children():
		if child is Control:
			if child.is_visible_in_tree() and child.focus_mode == Control.FocusMode.FOCUS_ALL:
				# print(".".repeat(_level) + child.name)
				list.push_back(child)
			if child.get_child_count() > 0:
				get_focusable_controls(child, _level + 1, list)

static  func find_values_in_string(text):
	var matches = regex_test.search_all(text)
	var results = []
	if matches.is_empty(): return results
	# Find changes on message
	for result_match : RegExMatch in matches:
		var result = result_match.get_string()
		var update_name = result.replace("{", "").replace("}", "")
		results.push_back(update_name)
	return results

static func parse_message(message, values = {}) -> Dictionary:
	var results = { 
		"text": str(message), 
		"formated": str(message),
		"values": []
	}
	if !values.is_empty():
		results.values = find_values_in_string(results.text)
		results.formated = results.text.format(values)
	return results
