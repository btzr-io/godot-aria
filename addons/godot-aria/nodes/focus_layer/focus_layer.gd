extends CanvasLayer

var focus_control_node = preload("../focus_control/node.tscn")

func _ready() -> void:
	get_viewport().gui_focus_changed.connect(handle_focus_changed)

func handle_focus_changed(focus_control: Control) -> void:
	if focus_control is FocusControl:
		var aria_label = focus_control.area_target.aria_label
		GodotARIA.notify_screen_reader(aria_label)
		
func create_focus_control(area: AreaFocus2D) -> FocusControl:
	var focus_control : FocusControl = focus_control_node.instantiate()
	var size = null
	var prev_rect = null
	for owner_id : int in area.get_shape_owners():
		var shape : Shape2D = area.shape_owner_get_shape(owner_id, 0)
		var rect = shape.get_rect()
		if !size:
			size = rect.size
			prev_rect = rect
		else:
			size = prev_rect.size
			prev_rect = prev_rect.merge(rect)
			
	focus_control.size = size
	focus_control.area_target = area
	focus_control.global_position = area.global_position - size * 0.5
	$MainContainer.add_child(focus_control)
	return focus_control
	
