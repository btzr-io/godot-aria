extends Button
class_name FocusControl

var focus_control_scene = preload("../focus_control/node.tscn")
var target : AccessibleModule
var target_parent : Node2D

func _ready() -> void:
	focus_exited.connect(handle_blur)
	focus_entered.connect(handle_focus)
	if target:
		target_parent = target.get_parent()
		target.tree_exited.connect(handle_remove)

func handle_remove():
	queue_free()

func handle_focus():
	target.focus_entered.emit()
	
func handle_blur():
	target.focus_exited.emit()
	
func _process(delta: float) -> void:
	if target:
		size = target.focus_size
		global_position = target_parent.global_position - size * 0.5
