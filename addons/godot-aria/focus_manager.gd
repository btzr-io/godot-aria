extends Object
class_name FocusManager

var tree : SceneTree
var viewport : Viewport
var focus_root : Node
var focus_list = []

var trap_next_focus = false
var trap_prev_focus = false

var next_focus : Control
var prev_focus : Control
var last_focus : Control

# Called when the node enters the scene tree for the first time.
func _init(current_tree, current_viewport)  -> void:
	if !OS.has_feature("web"): return
	tree = current_tree
	viewport = current_viewport
	viewport.gui_focus_changed.connect(self.handle_focus_changed)

func has_focus():
	if !OS.has_feature("web"): return
	return viewport.gui_get_focus_owner() != null

func scan_focus_list():
	if !OS.has_feature("web"): return
	focus_list.clear()
	GODOT_ARIA_UTILS.get_focusable_controls(tree.current_scene, focus_list)

func find_auto_focus_list():
	if !OS.has_feature("web"): return
	return focus_list.filter(
		func(item: Control) -> bool:
			if "auto_focus" in item:
				return item.auto_focus
			return false
	)

func focus_end() -> void:
	if !OS.has_feature("web"): return
	if !focus_list.is_empty():
		focus_list[focus_list.size()-1].grab_focus()

func focus_start() -> void:
	if !OS.has_feature("web"): return
	if !focus_list.is_empty():
		focus_list[0].grab_focus()

func restore_focus(focus_position: String = "FIRST"):
	if !OS.has_feature("web"): return
	scan_focus_list()
	if focus_list.is_empty(): return
	if focus_position == "START":
		focus_start()
	if focus_position == "END":
		focus_end()
	if focus_position == "LAST":
		if focus_list.has(last_focus):
			last_focus.grab_focus()
	if focus_position == "NEXT":
		if last_focus and next_focus:
			next_focus.grab_focus()
	if focus_position == "PREV":
		if last_focus and prev_focus:
			prev_focus.grab_focus()


func trap_focus():
	if !OS.has_feature("web"): return
	if GodotARIA.aria_proxy:
		trap_next_focus = true
		trap_prev_focus = true
		GodotARIA.aria_proxy.update_trap_focus(true, true)

func handle_focus_changed(control: Control):
	if !OS.has_feature("web"): return
	scan_focus_list()
	next_focus = control.find_next_valid_focus()
	prev_focus = control.find_prev_valid_focus()
	last_focus = control

	# Prevent focus trap
	if !focus_list.is_empty():
		trap_prev_focus = !control.focus_previous.is_empty() or prev_focus != focus_list[focus_list.size() - 1]
		trap_next_focus = !control.focus_next.is_empty() or next_focus != focus_list[0]
	else:
		trap_prev_focus = false
		trap_next_focus = false

	if GodotARIA.aria_proxy:
		GodotARIA.aria_proxy.update_trap_focus(trap_prev_focus, trap_next_focus)
