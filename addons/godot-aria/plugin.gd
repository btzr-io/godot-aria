@tool
extends EditorPlugin

# Replace this value with a PascalCase autoload name, as per the GDScript style guide.
const AUTOLOAD_NAME = "GodotARIA"

func _enable_plugin():
	# add_custom_type("AreaFocus2D", "Area2D", preload("nodes/area_focus_2d.gd"), preload("icons/Area2D.svg"))
	# The autoload can be a scene or script file.
	add_autoload_singleton(AUTOLOAD_NAME, "res://addons/godot-aria/godot_aria.gd")
	
func _disable_plugin():
	remove_autoload_singleton(AUTOLOAD_NAME)
