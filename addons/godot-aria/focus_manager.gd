extends Object
class_name FocusManager

var tree : SceneTree
var viewport : Viewport
var focus_list = []

var trap_next_focus = false
var trap_prev_focus = false

var next_focus : Control
var prev_focus : Control
var last_focus : Control
var active_focus : Control


# Called when the node enters the scene tree for the first time.
func _init(current_tree, current_viewport)  -> void:
	tree = current_tree
	viewport = current_viewport
	viewport.gui_focus_changed.connect(self.handle_focus_changed)

func scan_focus_list():
	GODOT_ARIA_UTILS.get_all_controls(tree.current_scene, 0, focus_list)
	
func find_autofocus_list():
	return focus_list.filter(
		func(item: Control) -> bool:
			if "autofocus" in item:
				return item.autofocus
			return false
	)
	
func handle_focus_changed(control: Control):
	scan_focus_list()
	last_focus = active_focus
	next_focus = control.find_next_valid_focus()
	prev_focus = control.find_prev_valid_focus()
	active_focus = control
	# Prevent focus trap
	if !focus_list.is_empty():
		trap_prev_focus = prev_focus != focus_list[focus_list.size()- 1]
		trap_next_focus = next_focus != focus_list[0]
	else:
		trap_prev_focus = false
		trap_next_focus = false
	if GodotARIA.aria_proxy:
		GodotARIA.aria_proxy.update_trap_focus(trap_prev_focus, trap_next_focus)
