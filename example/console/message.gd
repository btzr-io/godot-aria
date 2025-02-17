extends PanelContainer
@onready var content : RichTextLabel = $MessageContent
@onready var content_accessible_node : AccessibleNode = GodotARIA.get_accessible_node(content)
@onready var content_id = content_accessible_node._get_id()
@onready var style_normal = preload("res://example/console/styles/message_normal.tres")
@onready var style_focus = preload("res://example/console/styles/message_focus.tres")
var active : bool = false :
	set(value):
		active = value
		_toggle_active(value)

func _toggle_active(toggled) -> void:
	if toggled:
		content.add_theme_stylebox_override('normal', style_focus)
		await get_tree().process_frame
		content_accessible_node.update_element_area()
		GodotARIA.aria_proxy.set_active_descendant(content_id)
	else:
		content.add_theme_stylebox_override('normal', style_normal)
