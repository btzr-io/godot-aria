extends Button
class_name FocusControl
var focus_control_scene = preload("../focus_control/node.tscn")
var area_target : AreaFocus2D

func _ready() -> void:
	focus_exited.connect(handle_blur)
	focus_entered.connect(handle_focus)
	if area_target:
		area_target.tree_exited.connect(handle_remove)
		if area_target.auto_focus:
			grab_focus()

func handle_remove():
	queue_free()

func handle_focus():
	area_target.focus_entered.emit()
	
func handle_blur():
	area_target.focus_exited.emit()

func _pressed() -> void:
	var aria_label = area_target.aria_description
	GodotARIA.notify_screen_reader(area_target.aria_description)
	
func _process(delta: float) -> void:
	if area_target:
		global_position = area_target.global_position - size * 0.5
