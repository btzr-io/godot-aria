@tool
extends Node
## Accessible Control module
class_name AccessibleControlModule

var target_parent : Control

func _get_configuration_warnings() -> PackedStringArray:
	var parent = get_parent()
	if parent is Control:
		return []
	return ["Use only for Control and inherited types."]

@export var auto_focus : bool = false

@export_category("Accessibility")
@export var aria_label : String

func _enter_tree() -> void:
	target_parent = get_parent()
	target_parent.visibility_changed.connect(handle_visibility_change)
	target_parent.focus_entered.connect(handle_focus)

func _ready() -> void:
	if auto_focus: grab_focus()

func grab_focus():
	if target_parent.is_visible_in_tree():
		target_parent.grab_focus()

func handle_focus() -> void:
	if aria_label:
		GodotARIA.notify_screen_reader(aria_label)

func handle_visibility_change() -> void:
	if auto_focus: grab_focus()
