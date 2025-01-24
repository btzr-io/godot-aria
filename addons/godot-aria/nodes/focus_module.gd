@tool
extends Node
## Focus feature for Node2D module
class_name FocusModule

signal focus_exited
signal focus_entered

func _get_configuration_warnings() -> PackedStringArray:
	var parent = get_parent()
	if parent is Node2D:
		return []
	return ["Use only for Node2D and inherited types."]

# @export var auto_focus : bool = false

@export var focus_mode : Control.FocusMode = Control.FOCUS_ALL :
	set(value):
		focus_mode = value
		if Engine.is_editor_hint(): return
		if focus_control:
			focus_control.focus_mode = value
@export var focus_size : Vector2  = Vector2.ZERO :
	set(value):
		focus_size = value
		if Engine.is_editor_hint(): return
		if focus_control:
			focus_control.size = value
		
@export var focus_style : StyleBox  : 
	set(value):
		focus_style = value
		if Engine.is_editor_hint(): return
		if focus_control and value:
			focus_control.add_theme_stylebox_override("focus", value)

var focus_control : FocusControl

func grab_focus():
	if Engine.is_editor_hint(): return
	if focus_control:
		focus_control.grab_focus()
		
func has_focus():
	if Engine.is_editor_hint(): return
	return focus_control != null and focus_control.has_focus()
	
func _enter_tree() -> void:
	if focus_size == Vector2.ZERO:
		focus_size = find_container_size(get_parent())
	if Engine.is_editor_hint(): return

	# focus_control = GodotARIA.register_focus(self)
func find_container_size(container) -> Vector2:
	var size = Vector2.ONE * 24.0
	var prev_rect = null
	if container is Shape2D:
		size = container.get_rect().size
	if container is TouchScreenButton:
		size = container.shape.get_rect().size
	if container is Sprite2D:
		size = container.get_rect().size
	if container is AnimatedSprite2D:
		size = container.sprite_frames.get_frame_texture(
			container.animation,
			container.frame
		).get_size()
	if container is Area2D:
		for owner_id : int in container.get_shape_owners():
			var shape : Shape2D = container.shape_owner_get_shape(owner_id, 0)
			var rect = shape.get_rect()
			if !size:
				size = rect.size
				prev_rect = rect
			else:
				size = prev_rect.size
				prev_rect = prev_rect.merge(rect)
	return size * container.get_global_transform().get_scale()
