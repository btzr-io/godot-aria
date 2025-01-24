extends CanvasLayer

var focus_control_node = preload("../focus_control/node.tscn")

func _ready() -> void:
	if !OS.has_feature("web"): return
	get_viewport().gui_focus_changed.connect(handle_focus_changed)

func handle_focus_changed(focus_control: Control) -> void:
	if !OS.has_feature("web"): return
	if focus_control is FocusControl:
		var aria_label = focus_control.target.aria_label
		GodotARIA.notify_screen_reader(aria_label)

func create_focus_control(target:  FocusModule) -> FocusControl:
	if !OS.has_feature("web"): return
	var focus_control : FocusControl = focus_control_node.instantiate()
	var target_parent = target.get_parent()
	focus_control.size = target.focus_size
	focus_control.target = target
	focus_control.global_position = target_parent.global_position - focus_control.size * 0.5
	focus_control.focus_mode = target.focus_mode
	if target.focus_style:
		focus_control.add_theme_stylebox_override("focus", target.focus_style)
	$MainContainer.add_child(focus_control)
	return focus_control
