@tool
@icon('./icon.svg')
extends PanelContainer
class_name WebTextInput

## Hybrid control that renders a native <input> element on top of the godot canvas.
##
## The global transform and modulate alpha is synced to css transform and opacity.
## @experimental

var content_scene = preload("./content.tscn")

signal on_input
signal on_change

const INPUT_TYPES = "text,email,date,date-local,month,number,password,tel,time,search,url,week"
const INPUT_MODES = "none,text,email,decimal,numeric,tel,search,url"

## The id global attribute defines an identifier (ID) for the <input> element which must be unique in the whole document.
@export var id  : String
## A string specifying the type of <input> element to render.
@export_custom(PROPERTY_HINT_ENUM, INPUT_TYPES) var type: String = "text"
## Provides a hint to browsers as to the type of virtual keyboard configuration to use when editing this element or its contents.
@export_custom(PROPERTY_HINT_ENUM, INPUT_MODES) var input_mode : String
## A string containing the value of the <input> element, or the empty string if the input element has no value set.
@export var value : String = ""
## Text that appears when the <input> element has no value set
@export var placeholder : String = "Placeholder text"
## Attribute to provide an accessible name for the <input> element
@export var aria_label : String
## Hint for form autofill feature
@export var auto_complete : String
## Maximum length (number of characters) of value
@export_range(0, 524288, 1,"or_great") var max_length : int = 0
## Attribute that defines whether the <input> element may be checked for spelling errors.
@export var spell_check : bool = false
## Boolean attribute, when present, the user can neither edit nor focus on <input> element.
@export var disabled: bool = false :
	set(value):
		disabled = value
		set_style(disabled_style if value else normal_style)
		if (GODOT_ARIA_UTILS.is_web()) and input_ref:
			input_ref.element.disabled = value

@export_category("Styles")
@export var disabled_style : StyleBox : 
	set(value):
		disabled_style = value
		if disabled:
			set_style(value)
@export var focus_style : StyleBox
@export var normal_style : StyleBox :
	set(value):
		normal_style = value
		set_style(value)
@export_subgroup("Colors")
@export var text_color : Color :
	set(value):
		placeholder_color = value
		set_css_property('--text_color', value)
		
@export var placeholder_color : Color :
	set(value):
		placeholder_color = value
		set_css_property('--placeholder_color', value)
		
@export var selection_color : Color :
	set(value):
		selection_color = value
		set_css_property('--selection_color', value)
		
@export var selection_text_color : Color :
	set(value):
		selection_text_color = value
		set_css_property('--selection_text_color', value)

var box : PanelContainer
var overlay_target : Label
var input_ref : GodotARIA.HTML_REF

# Events callbacks
var html_input_cb = JavaScriptBridge.create_callback(handle_html_input)
var html_change_cb = JavaScriptBridge.create_callback(handle_html_change)
var html_focus_cb = JavaScriptBridge.create_callback(handle_html_focus)
var html_focusout_cb = JavaScriptBridge.create_callback(handle_html_focusout)
var html_keydown_cb = JavaScriptBridge.create_callback(handle_html_keydown)
# Cache transforms
var element_transform : Dictionary
var prev_element_transform : Dictionary = {}

func set_style(new_style):
	if box and new_style:
		box.add_theme_stylebox_override('panel', new_style)

func has_html_focus() -> bool :
	if GODOT_ARIA_UTILS.is_web() and input_ref and input_ref.element:
		return GodotARIA.aria_proxy.has_focus(input_ref.element)
	return false
	
func set_css_property(property_name, property_value):
	if GODOT_ARIA_UTILS.is_web() and input_ref and input_ref.element:
		var formated = property_value
		if formated is Color:
			formated = GODOT_ARIA_UTILS.to_css_color(formated)
		input_ref.element.style.setProperty(property_name, formated)

func _enter_tree() -> void:
	# Don't render for non web builds
	if !Engine.is_editor_hint() and !OS.has_feature("web"):
			visible = false
	# Render contents if is editor or web:
	if (Engine.is_editor_hint() or OS.has_feature("web")) and !get_node_or_null("Box"):
		box = content_scene.instantiate()
		overlay_target = box.get_node_or_null("Label")
		add_child(box)
	# Set initial styles in editor
	if Engine.is_editor_hint():
		set_style(disabled_style if disabled else normal_style)
	# Default configuration
	clip_contents = true
	custom_minimum_size.x = 100
	custom_minimum_size.y = 24
	focus_mode = FOCUS_ALL
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	
	if GODOT_ARIA_UTILS.is_web():
		set_notify_transform(true)
		visibility_changed.connect(handle_visibility)
		focus_entered.connect(handle_focus)
		focus_exited.connect(handle_blur)
		# Initial value for element attributes
		var init_props = {
			'type': type,
			'value': value,
			'disabled': disabled,
			'ariaLabel': aria_label,
			'placeholder': placeholder,
			'spellcheck': spell_check
		}
		# Conditional props
		if max_length > 0:
			init_props['maxLength'] = max_length
			
		if auto_complete:
			init_props['autocomplete'] = auto_complete
		# Html element reference
		input_ref = GodotARIA.HTML_REF.new(id, "input", init_props)
		input_ref.element.addEventListener("focus", html_focus_cb)
		input_ref.element.addEventListener("focusout", html_focusout_cb)
		input_ref.element.addEventListener("input", html_input_cb)
		input_ref.element.addEventListener("change", html_change_cb)
		input_ref.element.addEventListener("keydown", html_keydown_cb)
		# Initial visibility
		handle_visibility()
		
func update_style_colors() -> void:
	if !input_ref or !input_ref.element: return
	var prop_colors = ['text_color', 'placeholder_color', 'selection_color', 'selection_text_color']
	for prop_name in prop_colors:
		var prop_value : Color = self[prop_name]
		if prop_value: set_css_property("--" + prop_name, prop_value)
		
func handle_visibility():
	var is_visible: bool = is_visible_in_tree()
	input_ref.update_style({'display': 'block' if is_visible else 'none'})
	
func handle_focus() -> void:
	if disabled: return
	set_style(focus_style)
	if GODOT_ARIA_UTILS.is_web():
		input_ref.element.focus()

func handle_html_focus(args):
	grab_focus()

func handle_html_focusout(args):
	release_focus()

func handle_html_input(args):
	on_input.emit(args)

func handle_html_change(args):
	on_change.emit(args)

func handle_html_keydown(args):
	var html_event : JavaScriptObject = args[0]
	if html_event.key == "Tab" and html_event.shiftKey:
		html_event.preventDefault()
		GodotARIA.aria_proxy.focus_enter_position = "PREV"
		GodotARIA.focus_canvas()
	elif html_event.key == "Tab" and !html_event.shiftKey:
		html_event.preventDefault()
		GodotARIA.aria_proxy.focus_enter_position = "NEXT"
		GodotARIA.focus_canvas()

func handle_blur():
	if disabled: return
	set_style(normal_style)

func _notification(what: int) -> void:
	if GODOT_ARIA_UTILS.is_web():
		if what == NOTIFICATION_PREDELETE:
			input_ref.free()
		if what == NOTIFICATION_TRANSFORM_CHANGED:
			force_redraw()

func force_redraw():
	element_transform = GODOT_ARIA_UTILS.get_control_css_transform(overlay_target)
	if element_transform.hash() != prev_element_transform.hash():
		prev_element_transform = element_transform
		queue_redraw()
		
func _draw() -> void:
	if !GODOT_ARIA_UTILS.is_web() or !element_transform: return
	GodotARIA.aria_proxy.redraw_element(
		id,
		element_transform.width, 
		element_transform.height, 
		element_transform.left, 
		element_transform.top, 
		element_transform.scale_x,
		element_transform.scale_y,
		element_transform.rotation,
		element_transform.opacity
	)
		
func _ready() -> void:
	# Initial render
	if GODOT_ARIA_UTILS.is_web():
		set_style(disabled_style if disabled else normal_style)
		update_style_colors()
		await(get_tree().process_frame)
		force_redraw()
