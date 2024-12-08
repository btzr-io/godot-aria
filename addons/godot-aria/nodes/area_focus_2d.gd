extends Area2D
## Accessible focusable Area2D
class_name AreaFocus2D

@export var focusable : bool = true
@export var auto_focus : bool = false
@export_category("Accessibility")
@export var aria_label : String
@export_multiline var aria_description : String

var focus_control : FocusControl

func grab_focus():
	if focus_control:
		focus_control.grab_focus()

	
func _enter_tree() -> void:
	focus_control = GodotARIA.register_focus_area(self)

func _exit_tree() -> void:
	print("exit")

	
	
