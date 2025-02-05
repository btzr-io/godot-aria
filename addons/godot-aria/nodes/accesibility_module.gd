@tool
extends Node
class_name AccessibilityModule
const ROLES = "button,checkbox,document,heading,meter,paragraph,progressbar,region,slider,switch"
const TEXT_ROLES = ['paragraph', 'heading']
const CONTAINER_ROLES = ['document', 'region']
const RANGE_ROLES = ['slider', 'meter', 'progressbar']
const READING_MODE_CONTAINERS = ['document']
const INTERACTIVE_ROLES = ["button","checkbox", "switch", "slider", "progressbar", "meter"]

const ARIA_PROPS = {
	"aria_busy": "ariaBusy",
	"aria_label": "ariaLabel",
	"aria_hidden": "ariaHidden",
	"aria_value_max": "ariaValueMin",
	"aria_value_min": "ariaValueMax",
	"aria_value_now": "ariaValueNow",
	"aria_value_text": "ariaValueText",
	"aria_description": "ariaDescription",
	"aria_orientation": "ariaOrientation",
	"aria_role_description": "ariaRoleDescription",
}

@export_custom(PROPERTY_HINT_ENUM, ROLES) var role : String
@export var label : String

var is_hovered : bool = false
var is_focus_on_click : bool = false

var container
var input_ref
var parent : Variant
var parent_element : Variant
var parent_control : Variant
var parent_module : Variant
var element_transform : Dictionary

static func is_valid_control(control: Control) -> bool:
	if control is BaseButton:
		return true
	if control is Range:
		return true
	if control is Label or control is RichTextLabel:
		return true
	return false

func is_content_for_reading_mode() -> bool:
	if INTERACTIVE_ROLES.has(role):
		return false
	if container is Control:
		var scaned : Control = container.get_parent_control()
		while scaned:
			var accessibility_module = GODOT_ARIA_UTILS.get_accessibility_module(scaned)
			if accessibility_module and READING_MODE_CONTAINERS.has(accessibility_module.role):
				return true
			scaned = scaned.get_parent_control()
	return false

func _get_role() -> String:
	if "aria_role" in container:
		return container.aria_role
	if container is Label or container is RichTextLabel:
		return "paragraph"
	if container is Slider:
		return "slider"
	if container is ProgressBar or container is TextureProgressBar:
		return "progressbar"
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
	if 'aria_label' in container:
		return container.aria_label
	if container is BaseButton:
		if "text" in container and !container.text.is_empty():
			return container.text
	return ""

func _get_text_content() -> String:
	if container is RichTextLabel:
		return container.get_parsed_text()
	elif 'text' in container:
		return container.text
	return ""

func _get_role_template() -> Variant:
	if !role: return
	
	# Use container role only for actual container nodes:
	if CONTAINER_ROLES.has(role):
		if container is not Container:
			return
			
	var template = {
		"id": _get_id(),
		"tag": "div",
		"props": {}
	}
	# Semantic HTML templates
	# <h1>...<h6>
	if role == "heading":
		template["tag"] = "h1"
		if "aria_level" in container:
			template["tag"] = "h" + str(container.aria_level)
			template["props"]["textContent"] = _get_text_content()
	# <p>text...</p>
	if role == "paragraph":
		template["tag"] = "p"
		template["props"]["textContent"] = _get_text_content()
		# If no "reading" mode container is detected then it should become one:
		if !is_content_for_reading_mode():
			template['props']['role'] = "document"
			template['props']['ariaRoleDescription'] = "paragraph"
	# Generic ARIA templates
	# <div role={role} aria-label={ariaLabel}></div>
	if  role not in TEXT_ROLES:
		template["props"]["role"] = role
		if !label.is_empty():
			template["props"]["ariaLabel"] = label
	# Checkbox template
	if role == "checkbox" or role == "switch":
		template["props"]["ariaChecked"] = false
		if container is BaseButton:
			template["props"]["ariaChecked"] = container.button_pressed
	# Slider template
	if RANGE_ROLES.has(role):
		if container is Range:
			template["props"]["ariaMin"] = container.min_value
			template["props"]["ariaMax"] = container.max_value
			template["props"]["ariaValueNow"] = container.value
			if container is HSlider:
				template["props"]['ariaOrientation'] = "horizontal"
			if container is VSlider:
				template["props"]['ariaOrientation'] = "vertical"
	
	# Map additional aria props
	for aria_prop in ARIA_PROPS:
		if aria_prop in container:
			template["props"][ARIA_PROPS[aria_prop]] = container[aria_prop]
	
	return template

func _get_configuration_warnings() -> PackedStringArray:
	var parent = get_parent()
	if parent is Control:
		return []
	return ["Use only for Control and inherited types."]

func _enter_tree() -> void:
	container = get_parent()
	if container:
		parent = container.get_parent()
	# Prevent exposing control to the accessibility tree
	if 'aria_hidden' in container:
		if container.aria_hidden: return
	# Get role and label from container
	var default_role = _get_role()
	var default_label = _get_label()
	if default_role: role = default_role
	if default_label: label = default_label
	
	if GODOT_ARIA_UTILS.is_web() and role:
		if container is Control:
			container.mouse_exited.connect(handle_mouse_exited)
			container.mouse_entered.connect(handle_mouse_entered)
			container.focus_entered.connect(handle_focus)
			container.focus_exited.connect(handle_unfocus)
			
			if parent is Control:
				parent.item_rect_changed.connect(handle_parent_rect_changed)
			container.item_rect_changed.connect(handle_item_rect_changed)
			container.visibility_changed.connect(handle_visibility)
			if 'value_changed' in container:
				container.value_changed.connect(handle_value_changed)
			if 'toggled' in container:
				container.toggled.connect(handle_toggled)
		# Html element reference
		var template : Dictionary = _get_role_template()
		if template:
			parent_element = _get_parent_element()
			input_ref = GodotARIA.HTML_REF.new(template["id"], template["tag"], template["props"], "hidden", parent_element)
			handle_visibility()
			
func handle_mouse_entered():
	is_hovered = true

func handle_mouse_exited():
	is_hovered = false

func handle_visibility():
	if GODOT_ARIA_UTILS.is_web():
		var is_visible: bool = container.is_visible_in_tree()
		input_ref.update_style({'display': 'block' if is_visible else 'none'})
		await(get_tree().process_frame)
		update_element_area()

func handle_parent_rect_changed():
	await(get_tree().process_frame)
	update_element_area()

func handle_item_rect_changed():
	await(get_tree().process_frame)
	update_element_area()

func _get_parent_element() -> Variant:
	parent_control = GODOT_ARIA_UTILS.get_parent_in_accesibility_tree(container)
	parent_module = GODOT_ARIA_UTILS.get_accessibility_module(parent_control)
	# Prevent invalid hierarchy
	if parent_module:
		# Only text content should be indside reading mode
		if INTERACTIVE_ROLES.has(role) and parent_module.role == "document":
			return null
		return parent_module.input_ref.element
	return null

func handle_focus() -> void:
	if GODOT_ARIA_UTILS.is_web():
		GodotARIA.aria_proxy.set_active_descendant(input_ref.element.id)


func handle_unfocus() -> void:
	if GODOT_ARIA_UTILS.is_web():
		if GodotARIA.aria_proxy.get_active_descendant() == input_ref.element.id:
			GodotARIA.aria_proxy.set_active_descendant()

func handle_toggled(toggled_on) -> void:
	if role == "checkbox" or role== "switch":
		input_ref.element['ariaChecked'] = toggled_on
		
func handle_value_changed(new_value) -> void:
	if GODOT_ARIA_UTILS.is_web():
		if 'value' in container:
			input_ref.element['ariaValueNow'] = new_value
			
func _notification(what: int) -> void:
		if what == NOTIFICATION_PREDELETE:
			if GODOT_ARIA_UTILS.is_web(): input_ref.free()

func _ready() -> void:
	# Initial render
	if GODOT_ARIA_UTILS.is_web():
		await(get_tree().process_frame)
		update_element_area()

func update_element_area() -> void:
	if GODOT_ARIA_UTILS.is_web():
		element_transform = GODOT_ARIA_UTILS.get_control_css_transform(container, parent_control)
	if !element_transform or !input_ref: return
	GodotARIA.aria_proxy.redraw_element(
		input_ref.element,
		GODOT_ARIA_UTILS.dictionary_to_js(element_transform),
		# Opacity is always set to zero for hidden DOM elements except containers:
		1.0 if CONTAINER_ROLES.has(role) else 0
	)
