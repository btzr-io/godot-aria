extends Area2D
## Accessible focusable Area2D
class_name AreaFocus2D

signal focus_exited
signal focus_entered


@export var auto_focus : bool = false

@export var focus_mode : Control.FocusMode = Control.FOCUS_ALL :
	set(value):
		focus_mode = value
		if focus_control:
			focus_control.focus_mode = value

@export var focus_style : StyleBox  : 
	set(value):
		focus_style = value
		if focus_control and value:
			focus_control.add_theme_stylebox_override("focus", value)

@export_category("Accessibility")
@export var aria_label : String
@export_multiline var aria_description : String
var focus_control : FocusControl

func grab_focus():
	if focus_control:
		focus_control.grab_focus()
		
func has_focus():
	return focus_control != null and focus_control.has_focus()
	
func _enter_tree() -> void:
	focus_control = GodotARIA.register_focus_area(self)
