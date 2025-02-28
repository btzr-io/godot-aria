@tool
extends Node
class_name AccessibleNode
const ROLES = "button,checkbox,document,group,heading,list,listitem,menu,meter,paragraph,progressbar,region,slider,switch"
const TEXT_ROLES = ['paragraph', 'heading']
const CONTAINER_ROLES = ['document', 'list', 'group', 'menu', 'region']
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
var ref
var parent : Variant
var parent_element : Variant
var parent_control : Variant
var parent_module : Variant
var element_transform : Dictionary
var godot_aria : Variant

# HTML EVENTS
var handle_html_click_cb = JavaScriptBridge.create_callback(handle_html_click)
var handle_html_value_changed_cb = JavaScriptBridge.create_callback(handle_html_value_changed)

static func is_valid_control(control: Control) -> bool:
	if control is BaseButton:
		return true
	if control is Range:
		return true
	if control is Label or control is RichTextLabel:
		return true
	return false

func is_content_for_reading_mode() -> bool:
	if !godot_aria or !godot_aria.aria_proxy:
		return false
	if INTERACTIVE_ROLES.has(role):
		return false
	if container is Control:
		var scaned : Control = container.get_parent_control()
		while scaned:
			var accessible_node = godot_aria.get_accessible_node(scaned)
			if accessible_node and READING_MODE_CONTAINERS.has(accessible_node.role):
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
	if 'aria_id' in container and container.aria_id is String:
		return container.aria_id
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
		if is_content_for_reading_mode():
			template["tag"] = "p"
			template["props"]["textContent"] = _get_text_content()
		else:
			template["props"]["role"] = "presentation"
			template["props"]["textContent"] = _get_text_content()
			# Speak content on focus
			template["props"]["ariaDescription"] = _get_text_content()
			# Prevent NVDA from speaking "section" before reading description
			template["props"]["ariaRoleDescription"] = " "

	# Generic ARIA templates
	# <div role={role} aria-label={ariaLabel}></div>
	if  role not in TEXT_ROLES:
		template["props"]["role"] = role
		template['props']['tabIndex'] = -1
		if !label.is_empty():
			template["props"]["ariaLabel"] = label

	# Generic button template
	if container is BaseButton:
		template['tag'] = 'buttton'
		if role == "button" and container.toggle_mode:
			template["props"]["ariaPressed"] = container.button_pressed

	# Checkbox template
	if role == "checkbox" or role == "switch":
		template["props"]["ariaChecked"] = false
		if container is BaseButton:
			template["props"]["ariaChecked"] = container.button_pressed

	# Slider template
	if RANGE_ROLES.has(role):
		if container is Range:
			# Use implicit role from semantics:
			template["props"].erase('role')
			template["props"]["min"] = container.min_value
			template["props"]["max"] = container.max_value
			template["props"]["value"] = container.value
			template["props"]["ariaValueNow"] = container.value
			if role == "progressbar":
				template["tag"] = "progress"
			if role == "meter":
				template["tag"] = "meter"
			if container is Slider:
				template["tag"] = 'input'
				template["props"]["type"] = "range"
				template["props"]["orient"] = _get_container_orientation()
				template["props"]["ariaOrientation"] = template["props"]["orient"]
	# Map additional aria props
	for aria_prop in ARIA_PROPS:
		if aria_prop in container:
			template["props"][ARIA_PROPS[aria_prop]] = container[aria_prop]
	return template

func _get_container_orientation() -> String:
	if container is HSlider:
		return "horizontal"
	if container is VSlider:
		return "vertical"
	return "horizontal"

func _get_configuration_warnings() -> PackedStringArray:
	var parent = get_parent()
	if parent is Control:
		return []
	return ["Use only for Control and inherited types."]

func _init() -> void:
	godot_aria = GODOT_ARIA_UTILS.get_safe_autoload()

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
		var template : Variant = _get_role_template()
		if template:
			parent_element = _get_parent_element()
			ref = HtmlReference.new(template["id"], template["tag"], template["props"], "hidden", parent_element)
			if container is BaseButton:
				ref.element.addEventListener('click', handle_html_click_cb)
			if container is Range:
				ref.element.addEventListener('input', handle_html_value_changed_cb)
			handle_visibility()

func handle_mouse_entered():
	is_hovered = true

func handle_mouse_exited():
	is_hovered = false

func handle_visibility():
	if GODOT_ARIA_UTILS.is_web():
		var is_visible: bool = container.is_visible_in_tree()
		ref.update_style({'display': 'block' if is_visible else 'none'})
		await(get_tree().process_frame)
		update_element_area()

func handle_parent_rect_changed():
	await(get_tree().process_frame)
	update_element_area()

func handle_item_rect_changed():
	await(get_tree().process_frame)
	update_element_area()

func handle_html_click(args):
	var event = args[0]
	# Focus on interaction
	if !container.has_focus(): container.grab_focus()

	if container is BaseButton:
		# Checkbox or switch
		if container.toggle_mode:
			container.button_pressed = !container.button_pressed
		else:
			container.pressed.emit()
			container._pressed()

func handle_html_value_changed(args):
	var event = args[0]
	# Focus on interaction
	if !container.has_focus(): container.grab_focus()
	if 'value' in container:
		container.value = float(event.target.value)

func _get_parent_element() -> Variant:
	if godot_aria:
		parent_control = godot_aria.get_parent_in_accesibility_tree(container)
		parent_module = godot_aria.get_accessible_node(parent_control)
	# Prevent invalid hierarchy
	if parent_module:
		# Only text content should be indside reading mode
		if !TEXT_ROLES.has(role) and parent_module.role == "document":
			return null
		return parent_module.ref.element
	return null

func handle_focus() -> void:
	if GODOT_ARIA_UTILS.is_web():
		if ref and godot_aria:
			godot_aria.aria_proxy.set_active_descendant(ref.element.id)

func handle_unfocus() -> void:
	if GODOT_ARIA_UTILS.is_web() and ref:
			if godot_aria and godot_aria.aria_proxy.get_active_descendant() == ref.element.id:
				godot_aria.aria_proxy.set_active_descendant()

func handle_toggled(toggled_on) -> void:
	if role == "button":
		ref.element['ariaPressed'] = toggled_on
	if role == "checkbox" or role== "switch":
		ref.element['ariaChecked'] = toggled_on

func handle_value_changed(new_value) -> void:
	if GODOT_ARIA_UTILS.is_web():
		if 'value' in container:
			ref.element.value  = new_value
			ref.element['ariaValueNow'] = new_value

func _notification(what: int) -> void:
		if what == NOTIFICATION_PREDELETE:
			if GODOT_ARIA_UTILS.is_web() and ref:
				ref.free()

func _ready() -> void:
	# Initial render
	if GODOT_ARIA_UTILS.is_web():
		await(get_tree().process_frame)
		update_element_area()

func update_property(prop_name : String, prop_value: Variant) -> void:
	if GODOT_ARIA_UTILS.is_web():
		if ref and ref.element:
			ref.element[prop_name] = prop_value

func update_element_area() -> void:
	if GODOT_ARIA_UTILS.is_web():
		element_transform = GODOT_ARIA_UTILS.get_control_css_transform(container, parent_control)
	if !godot_aria or !element_transform or !ref: return
	godot_aria.aria_proxy.redraw_element(
		ref.element,
		GODOT_ARIA_UTILS.dictionary_to_js(element_transform),
		# Opacity is always set to zero for hidden DOM elements except containers:
		1.0 if CONTAINER_ROLES.has(role) else 0
	)
