@tool
extends Node
class_name AccessibilityModule

const ROLES = "button,checkbox,switch,slider,heading,paragraph"
const FOCUS_MODES = "None,Click,All"

const NODE_2D_PROPS = {
	"focus_mode": {
		"name": "focus_mode",
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": FOCUS_MODES
	},
	"focus_size": {
		"name": "focus_size",
		"type": TYPE_VECTOR2,
	},
	"focus_style": {
		"name": "focus_style",
		"type": TYPE_OBJECT,
		"hint": PROPERTY_HINT_RESOURCE_TYPE,
		"hint_string": "StyleBox"
	}
}

const ROLE_PROPS = {}

var props_data : Dictionary = {}


@export_custom(PROPERTY_HINT_ENUM, ROLES) var role : String
@export var label : String

var is_hovered : bool = false
var is_focus_on_click : bool = false

var container
var input_ref
var element_transform : Dictionary
var html_input_cb : JavaScriptObject = JavaScriptBridge.create_callback(handle_html_input)
var html_change_cb : JavaScriptObject = JavaScriptBridge.create_callback(handle_html_change)
var html_click_cb : JavaScriptObject = JavaScriptBridge.create_callback(handle_html_click)
var html_focus_cb : JavaScriptObject = JavaScriptBridge.create_callback(handle_html_focus)
var html_focusout_cb : JavaScriptObject = JavaScriptBridge.create_callback(handle_html_focus)
var html_keydown_cb : JavaScriptObject = JavaScriptBridge.create_callback(handle_html_keydown)

static func is_valid_control(control: Control) -> bool:
	if control is Button:
		return true
	if control is Slider:
		return true
	if control is Label:
		return true
	return false
	
func _set(property: StringName, value: Variant) -> bool:
	if props_data.has(property):
		props_data[property] = value
		return true
	return false
		
func _get(property: StringName) -> Variant:
	if props_data.has(property):
		return props_data[property]
	return

func _get_role() -> String:
	if container is Label:
		return "paragraph"
	if container is Slider:
		return "slider"
	if container is CheckBox:
		return "checkbox"
	if container is CheckButton:
		return "switch"
	if container is Button:
		return "button"
	return ""
	
func _get_id() -> String:
	return role + "-" + name + "-" + str(get_instance_id())
	
func _get_label() -> String:
	if container is BaseButton:
		if "text" in container and !container.text.is_empty():
			return container.text
	return ""

func _get_role_template() -> Variant:
	if !role: return
	
	var template = { 
		"id": _get_id(),
		"tag": "input",
		"props": {}
	} 
	if role == "paragraph":
		template["tag"] = "p"
		template["props"]["textContent"] = container.text
	# <button type="button">
	if role == "button":
		template["tag"] = "button"
		template["props"]["type"] = role
		template["props"]["textContent"] = label
	# <input type="checkbox">
	if role == "checkbox":
		template["props"]["checked"] = false
		template["props"]["type"] = role
	# <button type="button" role="switch">
	if role == "switch":
		template["tag"] = "button"
		template["props"]["type"] = "button"
		template["props"]["role"] = role
		template["props"]["ariaChecked"] = false
	# <input type="range" >
	if role == "slider":
		template["props"]["type"] = "range"
		if container is Slider:
			template["props"]["min"] = container.min_value
			template["props"]["max"] = container.max_value
			template["props"]["value"] = container.value
	# <button role="tab" >
	if role == "tab":
		template["tag"] = "button"
		template["props"]["role"] = role
		template["props"]["textContent"] = label
		template["props"]["ariaSelected"] = false
	# Implicit label for <input>
	if template["tag"] == "input":
		template["props"]["ariaLabel"] = label
	return template
	
func _get_configuration_warnings() -> PackedStringArray:
	var parent = get_parent()
	if parent is Control:
		return []
	return ["Use only for Control and inherited types."]
	
func _get_property_list():
	if Engine.is_editor_hint(): 
		var list : Array = []
		if container is Node2D:
			for prop_name in NODE_2D_PROPS:
				list.append(NODE_2D_PROPS[prop_name])
		return list

func _property_can_revert(property: StringName):
	return props_data.has(property)

func _property_get_revert(property: StringName) -> Variant:
	if property == "focus_mode":
		return Control.FOCUS_ALL
	return
	
func _enter_tree() -> void:
	container = get_parent()
	# Get role and label from container
	var default_role = _get_role()
	var default_label = _get_label()
	if default_role: role = default_role 
	if default_label: label = default_label
	# Update conditional props
	if container is Node2D:
		notify_property_list_changed()
	if GODOT_ARIA_UTILS.is_web() and role:
		container.mouse_exited.connect(handle_mouse_exited)
		container.mouse_entered.connect(handle_mouse_entered)
		container.focus_entered.connect(handle_focus)
		container.visibility_changed.connect(handle_visibility)
		# Html element reference
		var template : Dictionary = _get_role_template()
		if template:
			input_ref = GodotARIA.HTML_REF.new(template["id"], template["tag"], template["props"], "hidden")
			if role == "paragraph": return
			input_ref.element.addEventListener("input", html_input_cb)
			input_ref.element.addEventListener("click", html_click_cb)
			input_ref.element.addEventListener("change", html_change_cb)
			input_ref.element.addEventListener("focus", html_focus_cb)
			input_ref.element.addEventListener("focusout", html_focusout_cb)
			input_ref.element.addEventListener("keydown", html_keydown_cb)
			
func handle_mouse_entered():
	is_hovered = true
	
func handle_mouse_exited():
	is_hovered = false
	
func handle_visibility():
	var is_visible: bool = container.is_visible_in_tree()
	input_ref.update_style({'display': 'block' if is_visible else 'none'})

func handle_focus() -> void:
	if 'disabled' in container:
		if container.disabled: return
	if GODOT_ARIA_UTILS.is_web():
		if !is_focus_on_click:
			input_ref.element.focus()
	# Reset flag
	is_focus_on_click = false
		
func _input(input: InputEvent):
	if input is InputEventMouseButton:
		if input.pressed and input.button_index == 1:	
			if is_hovered and !container.has_focus():
				is_focus_on_click = true

func handle_html_change(args):
	var html_event = args[0]
	if container is CheckBox:
		var new_state = html_event.target.checked
		container.button_pressed = new_state

func handle_html_input(args):
	var html_event : JavaScriptObject = args[0]
	if container is Slider:
		var new_value : float = float(html_event.target.value)
		container.value = new_value
		
func handle_html_focus(args):
	container.grab_focus()

func handle_html_focusout(args):
	container.release_focus()

func handle_html_click(args):
	var html_event : JavaScriptObject = args[0]
	if container is BaseButton:
		if !container.toggle_mode:
			# Trigger pressed events
			if "_pressed" in container:
				container._pressed()
			container.pressed.emit()

func handle_html_keydown(args):
	var html_event : JavaScriptObject = args[0]
	var prevent_arrow_keys = false
		
	if GodotARIA.aria_proxy.is_focus_trap(html_event, prevent_arrow_keys):
		html_event.preventDefault()
		if html_event.key == "Tab" and html_event.shiftKey:
			GodotARIA.aria_proxy.focus_enter_position = "PREV"
			GodotARIA.focus_canvas()
		elif html_event.key == "Tab" and !html_event.shiftKey:
			GodotARIA.aria_proxy.focus_enter_position = "NEXT"
			GodotARIA.focus_canvas()

func _notification(what: int) -> void:
	if GODOT_ARIA_UTILS.is_web():
		if what == NOTIFICATION_PREDELETE:
			input_ref.free()

func _ready() -> void:
	# Initial render
	if GODOT_ARIA_UTILS.is_web():
		await(get_tree().process_frame)
		update_element_area()

func update_element_area() -> void:
	if GODOT_ARIA_UTILS.is_web():
		element_transform = GODOT_ARIA_UTILS.get_control_css_transform(container)
	if !element_transform: return
	GodotARIA.aria_proxy.redraw_element(
		_get_id(),
		element_transform.width, 
		element_transform.height, 
		element_transform.left, 
		element_transform.top, 
		element_transform.scale_x,
		element_transform.scale_y,
		element_transform.rotation,
		# Opacity is always set to zero for hidden DOM elements
		0.0
	)
